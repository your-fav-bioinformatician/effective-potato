import numpy as np
from engine.user_vector_generator import UserVectorGenerator

class EntropyCalc:
    def __init__(self, user_gen: UserVectorGenerator, tau=0.8, bonus_weight=0.3):
        self.user_gen = user_gen
        self.tau = tau
        self.bonus_weight = bonus_weight 
        
        # 1. Matrix Normalization (Majors are already filtered by the generator!)
        self.major_vectors_norm = self._normalize_matrix(self.user_gen.all_major_vectors)
        
        # 2. Database Sync for Entropy State
        user_doc = self.user_gen.db["User_vectors"].find_one({"user_id": self.user_gen.user_id})
        
        if user_doc and "initial_entropy" in user_doc:
            self.h_initial = user_doc.get("initial_entropy")
            self.layer_initial_entropy = user_doc.get("layer_initial_entropy")
            self.current_layer = user_doc.get("current_layer", 1)
            print(f"DEBUG: Restored DB Entropy -> Global: {self.h_initial:.4f} | Layer: {self.layer_initial_entropy:.4f} | Layer: {self.current_layer}")
        else:
            self.h_initial = self._compute_current_entropy(self.user_gen.user_vector)
            self.layer_initial_entropy = self.h_initial
            self.current_layer = 1
            
            self.user_gen.db["User_vectors"].update_one(
                {"user_id": self.user_gen.user_id},
                {"$set": {
                    "initial_entropy": self.h_initial,
                    "layer_initial_entropy": self.layer_initial_entropy,
                    "current_layer": self.current_layer
                }},
                upsert=True
            )
            print(f"DEBUG: Initial Entropy calculated & saved: {self.h_initial:.4f}")
            
    def _normalize_matrix(self, matrix):
        norm = np.linalg.norm(matrix, axis=1, keepdims=True)
        norm[norm == 0] = 1
        return matrix / norm

    def _softmax(self, x):
        e_x = np.exp(x - np.max(x))
        return e_x / e_x.sum()

    def _compute_current_entropy(self, user_vec, subset_indices=None):
        u_norm = user_vec / (np.linalg.norm(user_vec) + 1e-9)
        
        target_matrix = self.major_vectors_norm
        if subset_indices is not None and len(subset_indices) > 0:
            target_matrix = self.major_vectors_norm[subset_indices]
            
        scores = np.dot(target_matrix, u_norm)
        probs = self._softmax(scores / self.tau)
        entropy = -np.sum(probs * np.log(probs + 1e-9))
        return entropy

    def get_next_best_question(self):
        current_global_entropy = self._compute_current_entropy(self.user_gen.user_vector)

        asked_ids = {item['id'] for item in self.user_gen.user_answers}
        unasked_questions = [q for q in self.user_gen.concept_questions if q['id'] not in asked_ids]

        positive_child_ids = set()
        negative_child_ids = set()
        q_lookup = {q['id']: q for q in self.user_gen.concept_questions}
        
        for ans in self.user_gen.user_answers:
            q_id = ans.get('id')
            val = ans.get('answer', 0)
            if q_id in q_lookup:
                children = q_lookup[q_id].get('child_ids', [])
                if val > 3:  
                    positive_child_ids.update(children)
                else:        
                    negative_child_ids.update(children)

        negative_child_ids = negative_child_ids - positive_child_ids

        current_layer_unasked = [q for q in unasked_questions if q.get('layer', 1) == self.current_layer]
        
        if not current_layer_unasked:
            return None 

        valid_layer_questions = [q for q in current_layer_unasked if q['id'] not in negative_child_ids]

        if not valid_layer_questions:
            valid_layer_questions = current_layer_unasked

        priority_candidates = [q for q in valid_layer_questions if q['id'] in positive_child_ids]
        
        candidates = priority_candidates if priority_candidates else valid_layer_questions
        
        best_question = None
        max_info_gain = -float('inf')
        answer_values = np.array([-1, -0.5, 0, 0.5, 1])

        # Pre-calculate base normalized vector for proper scaling (Fix 1 Simulation)
        user_v_norm = self.user_gen.user_vector / (np.linalg.norm(self.user_gen.user_vector) + 1e-9)

        for q in candidates:
            concept_vec = np.array(q["concept_vector"])
            weight_q = q.get("weight", 0)
            
            relative_indices = self._get_relative_major_indices(q.get("relative_majors", []))
            current_local_entropy = self._compute_current_entropy(self.user_gen.user_vector, relative_indices)

            c_norm = np.linalg.norm(concept_vec)
            if c_norm == 0: c_norm = 1

            alignment = np.dot(user_v_norm, concept_vec) / c_norm
            logits = (alignment * answer_values) / self.tau
            p_answers = self._softmax(logits)

            expected_global_entropy_q = 0
            expected_local_entropy_q = 0
            
            target_matrix_global = self.major_vectors_norm
            target_matrix_local = self.major_vectors_norm[relative_indices] if relative_indices else target_matrix_global

            for idx, answer_val in enumerate(answer_values):
                p_ans = p_answers[idx]
                if p_ans < 1e-5: continue

                delta = concept_vec * weight_q * answer_val
                
                # Fix 1 Simulation applied: Add delta to the NORMALIZED vector, not the unscaled one
                u_simulated = user_v_norm + delta
                u_simulated = u_simulated / (np.linalg.norm(u_simulated) + 1e-9)
                
                scores_global = np.dot(target_matrix_global, u_simulated)
                probs_global = self._softmax(scores_global / self.tau)
                expected_global_entropy_q += p_ans * (-np.sum(probs_global * np.log(probs_global + 1e-9)))

                scores_local = np.dot(target_matrix_local, u_simulated)
                probs_local = self._softmax(scores_local / self.tau)
                expected_local_entropy_q += p_ans * (-np.sum(probs_local * np.log(probs_local + 1e-9)))
            
            global_gain = current_global_entropy - expected_global_entropy_q
            local_gain = current_local_entropy - expected_local_entropy_q
            
            total_gain = global_gain + (self.bonus_weight * local_gain)

            # Fix 2: Discard Redundancy. If maximum possible gain is tiny, skip it mathematically.
            if total_gain < 1e-4:
                continue

            if total_gain > max_info_gain:
                max_info_gain = total_gain
                best_question = q

        return best_question
        
    def _get_relative_major_indices(self, relative_majors):
        indices = []
        for r_id in relative_majors:
            if r_id in self.user_gen.major_id_to_index_map: 
                indices.append(self.user_gen.major_id_to_index_map[r_id])
        return indices

    def _update_layer_in_db(self):
        self.user_gen.db["User_vectors"].update_one(
            {"user_id": self.user_gen.user_id},
            {"$set": {
                "layer_initial_entropy": self.layer_initial_entropy,
                "current_layer": self.current_layer
            }}
        )

    def run_optimization_step(self):
        # Fix 3: Check for Neutrality Fatigue (15 consecutive neutral answers)
        consecutive_neutrals = 0
        # Iterate backwards through answers to count consecutive 3s (Neutral)
        for ans in reversed(self.user_gen.user_answers):
            if ans.get("answer", 0) == 3: 
                consecutive_neutrals += 1
            else:
                break
                
        if consecutive_neutrals >= 15:
            print("DEBUG: 15 consecutive neutral answers detected. Stopping assessment early.")
            self.user_gen._save_and_reset()
            return {"status": "completed", "reason": "neutrality_fatigue"}

        h_current = self._compute_current_entropy(self.user_gen.user_vector)
        
        global_drop_ratio = 0 if self.h_initial == 0 else (self.h_initial - h_current) / self.h_initial
        layer_drop_ratio = 0 if self.layer_initial_entropy == 0 else (self.layer_initial_entropy - h_current) / self.layer_initial_entropy

        print(f"DEBUG: Layer {self.current_layer} | Global Drop: {global_drop_ratio * 100:.2f}% | Layer Drop: {layer_drop_ratio * 100:.2f}%")

        if global_drop_ratio >= 0.70 or layer_drop_ratio >= 0.70:
            print("Confidence >= 70%. Stopping assessment immediately.")
            self.user_gen._save_and_reset()
            return {"status": "completed", "reason": "extreme_confidence_met"}

        if global_drop_ratio >= 0.50 or layer_drop_ratio >= 0.50:
            print(f"Confidence >= 50%. Skipping remaining questions and advancing to Layer {self.current_layer + 1}.")
            self.current_layer += 1
            self.layer_initial_entropy = h_current 
            self._update_layer_in_db() 

        best_q = self.get_next_best_question()

        if best_q is None:
            max_layers = max([q.get('layer', 1) for q in self.user_gen.concept_questions])
            if self.current_layer >= max_layers:
                print("All layers exhausted. Finishing.")
                self.user_gen._save_and_reset()
                return {"status": "completed", "reason": "all_layers_exhausted"}
            else:
                print(f"Layer {self.current_layer} exhausted. Advancing to Layer {self.current_layer + 1}.")
                self.current_layer += 1
                self.layer_initial_entropy = h_current
                self._update_layer_in_db() 
                best_q = self.get_next_best_question()

        if best_q is None:
            self.user_gen._save_and_reset()
            return {"status": "completed", "reason": "no_valid_questions_remaining"}

        total_qs = len(self.user_gen.concept_questions)
        answered_qs = len(self.user_gen.user_answers)
        is_final = (answered_qs + 1) >= total_qs
        
        self.user_gen._restore_active_question(best_q['id'], is_final=is_final)

        return {
            "status": "final_question" if is_final else "next_question",
            "question_data": best_q,
            "id": best_q['id']
        }