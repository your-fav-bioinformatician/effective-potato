import pymongo
import pyodbc
import numpy as np
import datetime


class UserVectorGenerator:
    def __init__(self, user_id, db_name="UniBridge_vectors", connection_string="mongodb://localhost:27017/"):
        self.client = pymongo.MongoClient(connection_string)
        self.db = self.client[db_name]
        self.user_id = user_id

        print(f"DEBUG: Connected to MongoDB. DB: '{db_name}'")

        # State variables
        self.neutral_vector = None
        self.all_major_vectors = None
        self.user_vector = None
        self.concept_questions = []

        self.active_question = None
        self.active_question_index = -1
        self.is_active_question_final = False
        self.user_answers = []

        # 1. Load Base Data
        self._load_major_vectors()
        self._load_concept_vectors()
        self._calculate_dynamic_weights()

        # 2. Initialize User Vector
        self._initialize_user_state()

    def _get_sql_connection(self):
        try:
            conn_str = (
                "Driver={ODBC Driver 17 for SQL Server};"
                "Server=.\\SQLEXPRESS;"
                "Database=Users_db;"
                "Trusted_Connection=yes;"
                "TrustServerCertificate=yes;"
            )
            return pyodbc.connect(conn_str)
        except Exception as e:
            print(f"SQL Connect Error inside Generator: {e}")
            return None

    def _load_major_vectors(self):
        collection = self.db["Major_vector"]

        # Check raw count
        total_docs = collection.count_documents({})
        print(f"DEBUG: Major_vectors total documents: {total_docs}")

        cursor = collection.find({"vector": {"$exists": True}}, {"vector": 1})

        vectors = []
        for doc in cursor:
            vec = doc.get("vector")
            if isinstance(vec, list) and len(vec) > 0:
                vectors.append(vec)

        print(f"DEBUG: Extracted {len(vectors)} valid vectors from cursor.")

        if not vectors:
            print("CRITICAL ERROR: No vectors found in DB. Generator cannot function.")
            vectors = [np.zeros(768).tolist()]

        self.all_major_vectors = np.array(vectors, dtype=np.float64)
        self.neutral_vector = np.mean(self.all_major_vectors, axis=0)

    def _load_concept_vectors(self):
        collection = self.db["Concept_vectors"]
        cursor = collection.find({}, {"id": 1, "question": 1, "concept_vector": 1})
        self.concept_questions = list(cursor)
        self.concept_questions.sort(key=lambda x: x["id"])
        print(f"DEBUG: Loaded {len(self.concept_questions)} concept questions.")

    def _calculate_dynamic_weights(self):
        variances = []
        major_norms = np.linalg.norm(self.all_major_vectors, axis=1)
        major_norms[major_norms == 0] = 1.0

        for q in self.concept_questions:
            c_vec = np.array(q.get("concept_vector", []), dtype=np.float64)
            if c_vec.size == 0:
                variances.append(0)
                continue
            c_norm = np.linalg.norm(c_vec)
            if c_norm == 0:
                variances.append(0)
                continue

            if c_vec.shape[0] != self.all_major_vectors.shape[1]:
                variances.append(0)
                continue

            dot_products = np.dot(self.all_major_vectors, c_vec)
            similarities = dot_products / (major_norms * c_norm)
            similarities = np.clip(similarities, -1, 1)
            distances = 1 - similarities

            variance_q = np.mean(distances)
            variances.append(variance_q)

        total_variance = sum(variances)
        for i, q in enumerate(self.concept_questions):
            if total_variance > 0:
                q["weight"] = variances[i] / total_variance
            else:
                q["weight"] = 0

    def _get_user_mbti_type(self):
        """Fetches the MBTI string (e.g. 'INTJ') from SQL Users table."""
        conn = self._get_sql_connection()
        if not conn: return None
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT mbti FROM Users WHERE user_id = ?", (self.user_id,))
            row = cursor.fetchone()
            if row:
                return row[0]  # e.g., "INTJ"
            return None
        finally:
            conn.close()

    def _initialize_user_state(self):
        self.active_question = None
        self.active_question_index = -1
        self.is_active_question_final = False
        self.user_answers = []

        mbti_vector = None

        # 1. Get MBTI Type from SQL
        mbti_type = self._get_user_mbti_type()

        if mbti_type:
            print(f"DEBUG: Found MBTI type for user {self.user_id}: {mbti_type}")
            try:
                # 2. Search for vector in 'mbti_vectors' collection
                # Assuming collection schema: { "type": "INTJ", "vector": [...] }
                mbti_collection = self.db["mbti_vectors"]

                # Case-insensitive search
                mbti_doc = mbti_collection.find_one({"mbti": {"$regex": f"^{mbti_type}$", "$options": "i"}})

                if mbti_doc and "mbti_vector" in mbti_doc:
                    raw_vec = mbti_doc["mbti_vector"]
                    if len(raw_vec) > 0:
                        mbti_vector = np.array(raw_vec, dtype=np.float64)
                        print(f"DEBUG: Successfully loaded vector for {mbti_type}")
                    else:
                        print(f"DEBUG: Vector for {mbti_type} is empty.")
                else:
                    print(f"DEBUG: No vector found in 'mbti_vectors' collection for type: {mbti_type}")

            except Exception as e:
                print(f"Error fetching MBTI vector from Mongo: {e}")
        else:
            print(f"DEBUG: No MBTI type found in SQL for user {self.user_id}")

        # 3. Combine with Neutral
        if mbti_vector is not None:
            if mbti_vector.shape == self.neutral_vector.shape:
                # Add neutral vector on top of MBTI vector as requested
                combined = mbti_vector + self.neutral_vector
                self.user_vector = self._normalize_vector_l2(combined)
            else:
                print(f"Dimension mismatch: MBTI {mbti_vector.shape} vs Neutral {self.neutral_vector.shape}. Fallback.")
                self.user_vector = self.neutral_vector.copy()
        else:
            # Fallback if no MBTI data exists
            self.user_vector = self.neutral_vector.copy()

    def get_normalized_answer(self, answer):
        if not (1 <= answer <= 5):
            return 0.0
        return (answer - 3) / 2.0

    def _normalize_vector_l2(self, vec):
        norm = np.linalg.norm(vec)
        if norm == 0:
            return vec
        return vec / norm

    def set_active_question(self, question_id, is_final=False):
        for index, q in enumerate(self.concept_questions):
            if q.get("id") == question_id:
                self.active_question = q
                self.active_question_index = index
                self.is_active_question_final = is_final
                return q

        self.active_question = None
        self.active_question_index = -1
        self.is_active_question_final = False
        return None

    def _save_and_reset(self):
        try:
            user_collection = self.db["User_vectors"]
            document = {
                "user_id": self.user_id,
                "final_user_vector": self.user_vector.tolist(),
                "answers": self.user_answers,
                "updated_at": datetime.datetime.utcnow(),
                "status": "complete"
            }
            user_collection.insert_one(document)
            print(f"User {self.user_id} vector stored. Vector sum: {np.sum(self.user_vector)}")
        except Exception as e:
            print(f"Failed to save user vector: {e}")
        finally:
            self.client.close()
            self.active_question = None

    def process_answer(self, answer_int):
        if self.active_question is None:
            print("Warning: process_answer called without active question.")
            return self.user_vector

        concept_vector = np.array(self.active_question.get("concept_vector", []), dtype=np.float64)
        if concept_vector.size == 0:
            print("Warning: Active question has no vector.")
            return self.user_vector

        answer_val = self.get_normalized_answer(answer_int)
        weight = self.active_question.get("weight", 0)

        delta_vector = concept_vector * weight * answer_val

        self.user_vector = self.user_vector + delta_vector
        self.user_vector = self._normalize_vector_l2(self.user_vector)

        self.user_answers.append({
            "id": self.active_question.get("id"),
            "answer": answer_int
        })

        if self.is_active_question_final:
            self._save_and_reset()

        return self.user_vector