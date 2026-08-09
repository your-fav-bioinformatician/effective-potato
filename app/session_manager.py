from typing import Dict, Optional, Any
from bson import ObjectId
import pymongo
from engine.user_vector_generator import UserVectorGenerator
from engine.entropy_calc import EntropyCalc


class SessionManager:
    def __init__(self, mongo_uri: Optional[str] = None, db_name: Optional[str] = None):
        self.mongo_uri = mongo_uri
        self.db_name = db_name

    def get_session(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Reconstructs the session objects on-demand from database state.
        Works across multiple workers and survives server restarts.
        """
        if not self._is_active_session(user_id):
            return None

        generator = UserVectorGenerator(
            user_id=user_id,
            db_name=self.db_name,
            connection_string=self.mongo_uri
        )

        calculator = EntropyCalc(user_gen=generator, tau=0.2)

        return {
            "generator": generator,
            "calc": calculator
        }

    def create_session(self, user_id: str, mongo_uri: str, db_name: str) -> Dict[str, Any]:
        """Initializes a new session by recording active status in MongoDB."""
        self.mongo_uri = mongo_uri or self.mongo_uri
        self.db_name = db_name or self.db_name

        self._set_session_status(user_id, active=True)
        return self.get_session(user_id)

    def end_session(self, user_id: str):
        """Marks the session as ended in MongoDB."""
        print(f"Ending session for User ID: {user_id}")
        self._set_session_status(user_id, active=False)

    def _is_active_session(self, user_id: str) -> bool:
        """Verifies if user exists and session is active in MongoDB."""
        if not self.mongo_uri or not self.db_name:
            return True
        try:
            client = pymongo.MongoClient(self.mongo_uri)
            db = client[self.db_name]
            
            try:
                query = {"_id": ObjectId(user_id)}
            except Exception:
                query = {"user_id": user_id}

            user = db["users_data"].find_one(query)
            client.close()

            if not user:
                return False
            
            return user.get("session_active", True)
        except Exception as e:
            print(f"Session check error: {e}")
            return False

    def _set_session_status(self, user_id: str, active: bool):
        """Persists active state flag in MongoDB."""
        try:
            client = pymongo.MongoClient(self.mongo_uri)
            db = client[self.db_name]

            try:
                query = {"_id": ObjectId(user_id)}
            except Exception:
                query = {"user_id": user_id}

            db["users_data"].update_one(query, {"$set": {"session_active": active}})
            client.close()
        except Exception as e:
            print(f"Failed to update session status in DB: {e}")