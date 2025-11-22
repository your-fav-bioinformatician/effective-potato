import numpy as np
from engine.user_vector_generator import UserVectorGenerator


class EntropyCalc:
    def __init__(self, user_gen: UserVectorGenerator, tau=1.0):
        self.user_gen = user_gen
        self.tau = tau

        self.major_vectors_norm = self._normalize_matrix(self.user_gen.all_major_vectors)
        self.h_initial = self._compute_current_entropy(self.user_gen.user_vector)
        print(f"DEBUG: Initial Entropy calculated: {self.h_initial:.4f}")

    def _normalize_matrix(self, matrix):
        norm = np.linalg.norm(matrix, axis=1, keepdims=True)
        norm[norm == 0] = 1
        return matrix / norm

    def _softmax(self, x):
        e_x = np.exp(x - np.max(x))
        return e_x / e_x.sum()

    def _compute_current_entropy(self, user_vec):
        u_norm = user_vec / (np.linalg.norm(user_vec) + 1e-9)
        scores = np.dot(self.major_vectors_norm, u_norm)
        probs = self._softmax(scores / self.tau)
        entropy = -np.sum(probs * np.log(probs + 1e-9))
        return entropy

    def get_next_best_question(self):
        current_entropy = self._compute_current_entropy(self.user_gen.user_vector)

        asked_ids = {item['id'] for item in self.user_gen.user_answers}
        unasked_questions = [q for q in self.user_gen.concept_questions if q['id'] not in asked_ids]

        if not unasked_questions:
            return None

        best_question = None
        max_info_gain = -float('inf')
        answer_values = np.array([-1, -0.5, 0, 0.5, 1])

        for q in unasked_questions:
            concept_vec = np.array(q["concept_vector"])
            weight_q = q.get("weight", 0)

            c_norm = np.linalg.norm(concept_vec)
            if c_norm == 0: c_norm = 1

            user_v_norm = self.user_gen.user_vector / (np.linalg.norm(self.user_gen.user_vector) + 1e-9)
            alignment = np.dot(user_v_norm, concept_vec) / c_norm

            logits = (alignment * answer_values) / self.tau
            p_answers = self._softmax(logits)

            expected_entropy_q = 0
            for idx, answer_val in enumerate(answer_values):
                p_ans = p_answers[idx]
                if p_ans < 1e-5: continue

                delta = concept_vec * weight_q * answer_val
                u_simulated = self.user_gen.user_vector + delta
                u_simulated = u_simulated / (np.linalg.norm(u_simulated) + 1e-9)
                h_simulated = self._compute_current_entropy(u_simulated)
                expected_entropy_q += p_ans * h_simulated

            info_gain = current_entropy - expected_entropy_q
            if info_gain > max_info_gain:
                max_info_gain = info_gain
                best_question = q

        return best_question

    def run_optimization_step(self):
        """
        Determines next question and sets it on the generator with the correct is_final flag.
        """
        h_current = self._compute_current_entropy(self.user_gen.user_vector)

        if self.h_initial == 0:
            entropy_drop_ratio = 0
        else:
            entropy_drop_ratio = (self.h_initial - h_current) / self.h_initial

        print(f"DEBUG: Current Entropy: {h_current:.4f} | Drop: {entropy_drop_ratio * 100:.2f}%")

        # 1. Immediate Stop Condition
        if entropy_drop_ratio >= 0.25:
            print("Entropy drop >= 25%. Stopping early and saving.")
            self.user_gen._save_and_reset()
            return {"status": "completed", "reason": "confidence_threshold_met"}

        # 2. Find Best Question
        best_q = self.get_next_best_question()

        if best_q is None:
            print("No questions remaining. Finishing.")
            self.user_gen._save_and_reset()
            return {"status": "completed", "reason": "no_questions_left"}

        # 3. Check if this is the Final Question
        total_qs = len(self.user_gen.concept_questions)
        answered_qs = len(self.user_gen.user_answers)

        # If (currently answered + this one) == total, then this is the last one.
        is_final = (answered_qs + 1) >= total_qs

        # 4. Set Active Question on Generator with FLAG
        # This ensures process_answer knows what to do without external help
        self.user_gen.set_active_question(best_q['id'], is_final=is_final)

        status = "final_question" if is_final else "next_question"

        return {
            "status": status,
            "question": best_q,
            "id": best_q['id']
        }
