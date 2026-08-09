import pymongo
import numpy as np
import datetime
from bson import ObjectId

# --- 1. GLOBAL CACHE ---
# Prevents pulling heavy vectors from MongoDB on every API request
GLOBAL_CACHE = {
    "majors_raw": None,
    "concepts_raw": None,
    "mbti_raw": None,
}

class UserVectorGenerator:
    def __init__(self, user_id, db_name="UniBridge_vectors", connection_string="mongodb://localhost:27017/"):
        self.client = pymongo.MongoClient(connection_string)
        self.db = self.client[db_name]
        self.user_id = str(user_id)

        # State variables
        self.user_data = {}
        self.neutral_vector = None
        self.all_major_vectors = None
        self.major_id_to_index_map = {}
        self.user_vector = None
        self.concept_questions = []

        self.active_question = None
        self.active_question_index = -1
        self.is_active_question_final = False
        self.user_answers = []

        # Load and Calculate
        self._populate_global_cache()
        self._load_user_data()
        self._load_major_vectors()       # Filters from cache
        self._load_concept_vectors()     # Loads from cache
        self._calculate_dynamic_weights()# Vectorized math
        self._initialize_user_state()

    def _populate_global_cache(self):
        """Fetches large collections from MongoDB ONLY ONCE for the lifetime of the server."""
        global GLOBAL_CACHE
        if GLOBAL_CACHE["majors_raw"] is None:
            GLOBAL_CACHE["majors_raw"] = list(self.db["Major_vector"].find({"vector": {"$exists": True}}))
        
        if GLOBAL_CACHE["concepts_raw"] is None:
            GLOBAL_CACHE["concepts_raw"] = list(self.db["concept_vectors"].find({}, {
                "id": 1, "question": 1, "concept_vector": 1, 
                "layer": 1, "child_ids": 1, "parent_ids": 1, "relative_majors": 1
            }))
            GLOBAL_CACHE["concepts_raw"].sort(key=lambda x: x["id"])
            
        if GLOBAL_CACHE["mbti_raw"] is None:
            GLOBAL_CACHE["mbti_raw"] = list(self.db["mbti_vectors"].find({}))

    def _load_user_data(self):
        try:
            oid = ObjectId(self.user_id)
            user_doc = self.db["users_data"].find_one({"_id": oid})
            if user_doc:
                self.user_data = {
                    "gpa": float(user_doc.get("gpa", 0.0)),
                    "hs_type": user_doc.get("hs_type", ""),
                    "gender": user_doc.get("gender", ""),
                    "mbti": user_doc.get("mbti", "")
                }
            else:
                self.user_data = {"gpa": 0.0, "hs_type": "", "gender": "", "mbti": ""}
        except Exception:
            self.user_data = {"gpa": 0.0, "hs_type": "", "gender": "", "mbti": ""}

    def _load_major_vectors(self):
        global GLOBAL_CACHE
        vectors = []
        self.major_id_to_index_map = {}
        
        u_gpa = self.user_data.get("gpa", 0.0)
        u_hs = self.user_data.get("hs_type", "")
        u_gen = self.user_data.get("gender", "").upper()

        current_idx = 0
        for doc in GLOBAL_CACHE["majors_raw"]:
            vec = doc.get("vector")
            dept_id = doc.get("dept_id")
            elig = doc.get("eligibility", {})

            # Phase 1: Eligibility Pre-filtering
            m_hs = elig.get("hs")
            if u_hs and m_hs and u_hs != m_hs and m_hs != 'Both': continue
                
            m_gpa = float(elig.get("gpa", 0.0))
            if u_gpa < (m_gpa - 3.0): continue
                
            m_gen = elig.get("gender", "both").lower()
            if u_gen == 'F' and m_gen not in ['f', 'female', 'both', 'co-ed']: continue
            if u_gen == 'M' and m_gen not in ['m', 'male', 'both', 'co-ed']: continue

            if isinstance(vec, list) and len(vec) > 0:
                vectors.append(vec)
                if dept_id is not None:
                    self.major_id_to_index_map[dept_id] = current_idx
                current_idx += 1

        if not vectors:
            vectors = [np.zeros(768).tolist()]

        self.all_major_vectors = np.array(vectors, dtype=np.float64)
        self.neutral_vector = np.mean(self.all_major_vectors, axis=0)

    def _load_concept_vectors(self):
        global GLOBAL_CACHE
        import copy
        
        # 1. Get the surviving eligible major IDs from the map we just built
        eligible_major_ids = set(self.major_id_to_index_map.keys())
        
        # 2. Filter the questions as we copy them from the cache
        valid_questions = []
        for q in GLOBAL_CACHE["concepts_raw"]:
            r_majors = q.get("relative_majors", [])
            
            # STRICT FIX: The question MUST explicitly match an eligible major.
            # Empty arrays will now be rejected, preventing rogue DB entries.
            if r_majors and any(rm in eligible_major_ids for rm in r_majors):
                valid_questions.append(copy.deepcopy(q))
        self.concept_questions = valid_questions
        print(f"DEBUG: Eligibility applied. {len(eligible_major_ids)} majors and {len(self.concept_questions)} questions loaded.")
    def _calculate_dynamic_weights(self):
        """Fully vectorized weight calculation using numpy matrix broadcasting."""
        if not self.concept_questions:
            return

        # Stack all concept vectors into a single matrix (Concepts x 768)
        concept_matrix = np.array([q.get("concept_vector", np.zeros(self.all_major_vectors.shape[1])) 
                                   for q in self.concept_questions], dtype=np.float64)

        # Calculate Norms
        major_norms = np.linalg.norm(self.all_major_vectors, axis=1, keepdims=True)
        major_norms[major_norms == 0] = 1.0
        
        concept_norms = np.linalg.norm(concept_matrix, axis=1)
        concept_norms[concept_norms == 0] = 1.0

        # Calculate cosine similarities for ALL majors vs ALL concepts instantly
        dot_products = np.dot(self.all_major_vectors, concept_matrix.T)
        
        # Broadcasting norms to match the shape
        similarities = dot_products / (major_norms * concept_norms)
        distances = 1 - np.clip(similarities, -1, 1)

        # Calculate variance (mean distance per concept across all majors)
        variances = np.mean(distances, axis=0)
        total_variance = np.sum(variances)

        # Assign calculated weights back to the questions
        for i, q in enumerate(self.concept_questions):
            q["weight"] = variances[i] / total_variance if total_variance > 0 else 0

    def _initialize_user_state(self):
        global GLOBAL_CACHE
        self.active_question = None
        self.active_question_index = -1
        self.is_active_question_final = False
        self.user_answers = []

        # 1. CHECK MONGODB FOR IN-PROGRESS QUIZ
        user_vector_doc = self.db["User_vectors"].find_one({"user_id": self.user_id})

        if user_vector_doc and "current_user_vector" in user_vector_doc:
            # Resume existing session state
            self.user_vector = np.array(user_vector_doc["current_user_vector"], dtype=np.float64)
            self.user_answers = user_vector_doc.get("answers", [])
            
            # If the user was just assigned a question by /next_q, reload it into memory
            active_q_id = user_vector_doc.get("active_question_id")
            if active_q_id:
                self.is_active_question_final = user_vector_doc.get("is_final", False)
                self._restore_active_question(active_q_id)
            return

        # 2. IF FIRST TIME STARTING QUIZ (Calculate MBTI + Neutral)
        mbti_vector = None
        mbti_type = self.user_data.get("mbti", "").upper()

        if mbti_type:
            for mbti_doc in GLOBAL_CACHE["mbti_raw"]:
                if mbti_doc.get("mbti", "").upper() == mbti_type:
                    raw_vec = mbti_doc.get("mbti_vector", [])
                    if len(raw_vec) > 0:
                        mbti_vector = np.array(raw_vec, dtype=np.float64)
                    break

        if mbti_vector is not None and mbti_vector.shape == self.neutral_vector.shape:
            combined = mbti_vector + self.neutral_vector
            self.user_vector = self._normalize_vector_l2(combined)
        else:
            self.user_vector = self.neutral_vector.copy()

    
    def get_normalized_answer(self, answer):
        if not (1 <= answer <= 5): return 0.0
        return (answer - 3) / 2.0

    def _normalize_vector_l2(self, vec):
        norm = np.linalg.norm(vec)
        if norm == 0: return vec
        return vec / norm

    def _restore_active_question(self, question_id, is_final=False):
        for index, q in enumerate(self.concept_questions):
            if q.get("id") == question_id:
                self.active_question = q
                self.active_question_index = index
                self.is_active_question_final = is_final
                
                # SAVE TO MONGODB: So /process_a remembers this question
                self.db["User_vectors"].update_one(
                    {"user_id": self.user_id},
                    {"$set": {
                        "active_question_id": question_id, 
                        "is_final": is_final
                    }}
                )
                return q
                
        self.active_question = None
        self.active_question_index = -1
        self.is_active_question_final = False
        return None

    def _save_and_reset(self):
        try:
            # Replaced insert_one with update_one to prevent duplicates
            self.db["User_vectors"].update_one(
                {"user_id": self.user_id},
                {"$set": {
                    "final_user_vector": self.user_vector.tolist(),
                    "answers": self.user_answers,
                    "updated_at": datetime.datetime.utcnow(),
                    "status": "complete",
                    "active_question_id": None
                }}
            )
            print(f"User {self.user_id} vector finalized and stored.")
        finally:
            self.client.close()
            self.active_question = None

    def process_answer(self, answer_int):
        if self.active_question is None: return self.user_vector

        concept_vector = np.array(self.active_question.get("concept_vector", []), dtype=np.float64)
        if concept_vector.size == 0: return self.user_vector

        answer_val = self.get_normalized_answer(answer_int)
        weight = self.active_question.get("weight", 0)
        BOOST = 25.0
        delta_vector = concept_vector * weight * answer_val * BOOST

        self.user_vector = self.user_vector / (np.linalg.norm(self.user_vector) + 1e-9)
        self.user_vector = self.user_vector + delta_vector
        self.user_vector = self.user_vector / (np.linalg.norm(self.user_vector) + 1e-9)

        self.user_answers.append({
            "id": self.active_question.get("id"),
            "answer": answer_int
        })

        if self.is_active_question_final:
            self._save_and_reset()
        else:
            # SAVE INTERMEDIATE PROGRESS TO DB
            self.db["User_vectors"].update_one(
                {"user_id": self.user_id},
                {"$set": {
                    "current_user_vector": self.user_vector.tolist(),
                    "answers": self.user_answers,
                    "active_question_id": None # Cleared until /next_q sets it again
                }}
            )

        return self.user_vector