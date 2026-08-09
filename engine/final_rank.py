import psycopg2
import pymongo
import numpy as np
import math
import traceback
from bson import ObjectId

class FinalRank:
    def __init__(self, mongo_conn_str, db_name, sql_conn_str):
        self.mongo_client = pymongo.MongoClient(mongo_conn_str)
        self.mongo_db = self.mongo_client[db_name]
        self.sql_conn_str = sql_conn_str
        self.GPA_TOLERANCE = 3.0
        self.MAX_DISTANCE_KM = 150.0

    def _get_sql_connection(self, database_name):
        try:
            return psycopg2.connect(self.sql_conn_str)
        except Exception as e:
            print(f"!!! SQL CONNECT ERROR ({database_name}): {e}")
            raise e

    def _safe_float(self, val, default=0.0):
        try:
            if val is None: return default
            return float(val)
        except:
            return default

    def _get_user_data(self, user_id):
        print(f"DEBUG: Fetching User {user_id} from MongoDB...")
        try:
            collection = self.mongo_db["users_data"]
            try:
                oid = ObjectId(user_id)
                query = {"_id": oid}
            except:
                query = {"user_id": user_id}

            user_doc = collection.find_one(query)

            if not user_doc:
                raise ValueError(f"User {user_id} not found.")

            return {
                "lat": user_doc.get("lat"),
                "lon": user_doc.get("lon"),
                "gpa": user_doc.get("gpa"),
                "gender": user_doc.get("gender"),
                "hs": user_doc.get("hs_type")
            }
        except Exception as e:
            print(f"ERROR in _get_user_data: {e}")
            raise e

    def _get_dept_pool(self):
        print("DEBUG: Fetching Depts from Unis_db (SQL)...")
        conn = self._get_sql_connection("Unis_db")
        try:
            cursor = conn.cursor()
            # cursor.execute("USE Unis_db;")

            sql = """
                  SELECT d.dept_id, d.dept_name, d.lat, d.lon, d.gpa, d.hs, d.gender, 
                c.college_name, c.web, u.uni_name, u.uni_rank, u.is_private
                FROM departments d
                JOIN colleges c ON d.college_id = c.college_id
                JOIN universities u ON c.uni_id = u.uni_id
                  """
            cursor.execute(sql)
            rows = cursor.fetchall()
            columns = [column[0] for column in cursor.description]
            return [dict(zip(columns, row)) for row in rows]
        except Exception as e:
            print(f"ERROR in _get_dept_pool: {e}")
            traceback.print_exc()
            return []
        finally:
            conn.close()

    def _get_vectors_map(self):
        collection = self.mongo_db["Major_vector"]
        cursor = collection.find({}, {"dept_id": 1, "vector": 1, "description": 1})

        vector_map = {}
        for doc in cursor:
            try:
                did = int(doc.get("dept_id", -1))
                vec = doc.get("vector")
                if did != -1 and vec:
                    vector_map[did] = {
                        "vector": np.array(vec, dtype=np.float64),
                        "description": doc.get("description", "")
                    }
            except:
                pass
        return vector_map

    def _get_user_vector(self, user_id):
        collection = self.mongo_db["User_vectors"]
        doc = collection.find_one({"user_id": str(user_id), "status": "complete"}, sort=[("_id", -1)])
        if not doc:
            doc = collection.find_one({"user_id": str(user_id)}, sort=[("_id", -1)])
        if not doc: return np.zeros(768)

        keys = ["final_user_vector", "user_vector", "mbti_vector"]
        for k in keys:
            if k in doc and doc[k]:
                return np.array(doc[k], dtype=np.float64)
        return np.zeros(768)

    def generate_rankings(self, user_id):
        print(f"\n=== GENERATING RANKINGS FOR USER {user_id} ===")
        try:
            user_data = self._get_user_data(user_id)
            dept_pool = self._get_dept_pool()

            if not dept_pool: return []

            vector_map = self._get_vectors_map()
            user_vector = self._get_user_vector(user_id)

            norm = np.linalg.norm(user_vector)
            user_vector_norm = user_vector / norm if norm > 0 else user_vector

            scored_results = []

            for dept in dept_pool:
                d_id = int(dept.get('dept_id', -1))
                if d_id not in vector_map: continue

                # Safety validation (Matches Phase 1 filter logic exactly)
                u_hs = user_data.get('hs')
                d_hs = dept.get('hs')
                if u_hs and d_hs and u_hs != d_hs and d_hs != 'Both': continue

                d_gen = (dept.get('gender') or 'both').lower()
                u_gen = (user_data.get('gender') or '').upper()
                if u_gen == 'F' and d_gen not in ['f', 'female', 'both', 'co-ed']: continue
                if u_gen == 'M' and d_gen not in ['m', 'male', 'both', 'co-ed']: continue

                u_gpa = self._safe_float(user_data.get('gpa'))
                d_gpa = self._safe_float(dept.get('gpa'))
                if u_gpa < (d_gpa - self.GPA_TOLERANCE): continue

                dept_info = vector_map[d_id]
                d_vec = dept_info['vector']
                d_norm = np.linalg.norm(d_vec)
                d_vec_norm = d_vec / d_norm if d_norm > 0 else d_vec

                similarity = np.dot(user_vector_norm, d_vec_norm)

                rank_val = self._safe_float(dept.get('uni_rank'), 120)
                rank_score = (121 - rank_val) / 120.0

                final_score = (similarity * 0.7) + (rank_score * 0.3)

                scored_results.append({
                    "full_name": f"{dept.get('uni_name')} - {dept.get('college_name')} - {dept.get('dept_name')}",
                    "description": dept_info['description'],
                    "web": dept.get('web', ''),
                    "score": float(final_score),
                    "details": {"sim": float(similarity), "rank": float(rank_score)}
                })

            scored_results.sort(key=lambda x: x['score'], reverse=True)
            return scored_results[:5]

        except Exception as e:
            print(f"CRITICAL RANKING ERROR: {e}")
            traceback.print_exc()
            return []