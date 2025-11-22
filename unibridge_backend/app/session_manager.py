from typing import Dict, Optional, Any
from engine.user_vector_generator import UserVectorGenerator
from engine.entropy_calc import EntropyCalc


class SessionManager:
    def __init__(self):
        # In-memory storage: user_id -> {'generator': instance, 'calc': instance}
        # In production, consider using Redis or a database for persistence.
        self._sessions: Dict[int, Dict[str, Any]] = {}

    def get_session(self, user_id: int) -> Optional[Dict[str, Any]]:
        """Retrieves an active session for a user."""
        return self._sessions.get(user_id)

    def create_session(self, user_id: int, mongo_uri: str, db_name: str) -> Dict[str, Any]:
        # Initialize the Engine classes
        generator = UserVectorGenerator(
            user_id=user_id,
            db_name=db_name,
            connection_string=mongo_uri
        )

        calculator = EntropyCalc(user_gen=generator, tau=0.1)

        session_data = {
            "generator": generator,
            "calc": calculator
        }

        self._sessions[user_id] = session_data
        return session_data

    def end_session(self, user_id: int):
        """Removes the session from memory."""
        if user_id in self._sessions:
            print(f"Ending session for User ID: {user_id}")
            del self._sessions[user_id]