import pyodbc
import pymongo
import numpy as np
import math
import traceback


class FinalRank:
    def __init__(self, mongo_conn_str="mongodb://localhost:27017/", db_name="UniBridge_vectors"):
        self.mongo_client = pymongo.MongoClient(mongo_conn_str)
        self.mongo_db = self.mongo_client[db_name]
        self.GPA_TOLERANCE = 3.0
        self.MAX_DISTANCE_KM = 150.0

    def _get_sql_connection(self, database_name):
        try:
            conn_str = (
                "Driver={ODBC Driver 17 for SQL Server};"
                "Server=.\\SQLEXPRESS;"
                f"Database={database_name};"
                "Trusted_Connection=yes;"
                "TrustServerCertificate=yes;"
            )
            return pyodbc.connect(conn_str)
        except Exception as e:
            print(f"SQL Connection Error ({database_name}): {e}")
            raise e

    def _haversine_distance(self, lat1, lon1, lat2, lon2):
        if any(x is None for x in [lat1, lon1, lat2, lon2]):
            return float('inf')
        try:
            R = 6371
            d_lat = math.radians(float(lat2) - float(lat1))
            d_lon = math.radians(float(lon2) - float(lon1))
            a = (math.sin(d_lat / 2) ** 2 +
                 math.cos(math.radians(float(lat1))) * math.cos(math.radians(float(lat2))) *
                 math.sin(d_lon / 2) ** 2)
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
            return R * c
        except (ValueError, TypeError):
            return float('inf')

    def _get_user_data(self, user_id):
        print(f"DEBUG: Fetching User {user_id} from Users_db...")
        conn = self._get_sql_connection("Users_db")
        try:
            cursor = conn.cursor()
            cursor.execute("USE Users_db;")

            # Simple query first
            sql = "SELECT lat, lon, gpa, gender, hs_type FROM [dbo].[Users] WHERE user_id = ?"
            cursor.execute(sql, (user_id,))
            row = cursor.fetchone()

            if not row:
                print(f"ERROR: User {user_id} not found.")
                raise ValueError(f"User {user_id} not found.")

            data = {
                "lat": row[0], "lon": row[1], "gpa": row[2], "gender": row[3], "hs_type": row[4]
            }
            print(f"DEBUG: User Data: {data}")
            return data
        except Exception as e:
            print(f"ERROR in _get_user_data: {e}")
            raise e
        finally:
            conn.close()

    def _get_dept_pool(self):
        conn = self._get_sql_connection("Unis_db")
        try:
            cursor = conn.cursor()
            # Wrap in try/except to catch missing column errors
            try:
                sql = """
                      SELECT d.dept_id, \
                             d.dept_name, \
                             d.lat, \
                             d.lon, \
                             d.gpa, \
                             d.hs, \
                             d.gender, \
                             c.college_name, \
                             c.web, \
                             u.uni_name, \
                             u.uni_rank, \
                             u.is_private
                      FROM Departments d
                               JOIN Colleges c ON d.college_id = c.college_id
                               JOIN Universities u ON c.uni_id = u.uni_id \
                      """
                cursor.execute(sql)
                rows = cursor.fetchall()
            except Exception as sql_err:
                print(f"SQL QUERY FAILED (Check your Unis_db Schema!): {sql_err}")
                return []

            if not rows:
                print("WARNING: No departments found in Unis_db.")
                return []

            columns = [column[0] for column in cursor.description]
            results = []
            for row in rows:
                results.append(dict(zip(columns, row)))

            print(f"DEBUG: Fetched {len(results)} departments.")
            return results
        finally:
            conn.close()

    def _get_vectors_map(self):
        collection = self.mongo_db["Major_vector"]
        cursor = collection.find({}, {"dept_id": 1, "vector": 1, "description": 1})

        vector_map = {}
        for doc in cursor:
            if "dept_id" in doc and "vector" in doc:
                vector_map[doc["dept_id"]] = {
                    "vector": np.array(doc["vector"], dtype=np.float64),
                    "description": doc.get("description", "No description.")
                }
        return vector_map

    def _get_user_vector(self, user_id):
        collection = self.mongo_db["User_vectors"]
        doc = collection.find_one(
            {"user_id": user_id, "status": "complete"},
            sort=[("updated_at", -1)]
        )

        if not doc:
            # Fallback for testing
            doc = collection.find_one({"user_id": user_id}, sort=[("_id", -1)])

        if not doc:
            print(f"WARNING: No vector found for User {user_id}")
            return np.zeros(768)

        if "final_user_vector" in doc:
            return np.array(doc["final_user_vector"], dtype=np.float64)
        elif "user_vector" in doc:
            return np.array(doc["user_vector"], dtype=np.float64)
        elif "mbti_vector" in doc:
            return np.array(doc["mbti_vector"], dtype=np.float64)

        return np.zeros(768)

    def _normalize_vector(self, vec):
        norm = np.linalg.norm(vec)
        if norm == 0: return vec
        return vec / norm

    def generate_rankings(self, user_id):
        print(f"--- Ranking Process Started for User {user_id} ---")
        try:
            user_data = self._get_user_data(user_id)
            dept_pool = self._get_dept_pool()

            if not dept_pool:
                # Return empty list instead of crashing, so frontend sees "No Results" instead of error
                print("DEBUG: Returning empty results (No Depts).")
                return []

            vector_map = self._get_vectors_map()
            user_vector = self._get_user_vector(user_id)
            user_vector_norm = self._normalize_vector(user_vector)

            filtered_candidates = []

            for dept in dept_pool:
                # 1. HS Filter
                u_hs = user_data.get('hs_type')
                d_hs = dept.get('hs')
                if u_hs and d_hs and u_hs != d_hs: continue

                # 2. Gender Filter
                d_gen = (dept.get('gender') or 'both').lower()
                u_gen = (user_data.get('gender') or '').upper()
                if u_gen == 'F' and d_gen not in ['f', 'female', 'both', 'co-ed']: continue
                if u_gen == 'M' and d_gen not in ['m', 'male', 'both', 'co-ed']: continue

                # 3. GPA Filter
                try:
                    u_gpa = float(user_data.get('gpa') or 0)
                    d_gpa = float(dept.get('gpa') or 0)
                    if u_gpa < (d_gpa - self.GPA_TOLERANCE): continue
                except:
                    pass

                # 4. Vector Check
                # Robust ID checking (int vs string)
                d_id = dept.get('dept_id')
                if d_id not in vector_map:
                    # Try string conversion if int failed
                    # if str(d_id) not in vector_map: continue
                    continue

                filtered_candidates.append(dept)

            print(f"DEBUG: {len(filtered_candidates)} candidates passed filtering.")

            scored_results = []
            for dept in filtered_candidates:
                dept_vec_data = vector_map[dept['dept_id']]
                dept_vec = dept_vec_data['vector']

                dept_vec_norm = self._normalize_vector(dept_vec)
                similarity = np.dot(user_vector_norm, dept_vec_norm)

                # Rank Bias
                max_rank = 120
                rank = dept.get('uni_rank') or max_rank
                if not isinstance(rank, (int, float)): rank = max_rank
                if rank > max_rank: rank = max_rank
                if rank < 1: rank = 1

                rank_score = (max_rank + 1 - rank) / max_rank

                final_score = (similarity * 0.7) + (rank_score * 0.3)

                scored_results.append({
                    "full_name": f"{dept.get('uni_name')} - {dept.get('college_name')} - {dept.get('dept_name')}",
                    "description": dept_vec_data['description'],
                    "web": dept.get('web', ''),
                    "score": float(final_score),
                    "details": {
                        "similarity": float(similarity),
                        "rank_bias": float(rank_score)
                    }
                })

            scored_results.sort(key=lambda x: x['score'], reverse=True)
            return scored_results[:5]

        except Exception as e:
            print(f"CRITICAL RANKING ERROR: {e}")
            traceback.print_exc()  # Print full stack trace to terminal
            # Return empty list so frontend doesn't get 500
            return []