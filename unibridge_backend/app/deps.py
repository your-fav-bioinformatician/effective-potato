from app.session_manager import SessionManager
from engine.final_rank import FinalRank

# --- Configuration ---
MONGO_CONNECTION_STRING = "mongodb://localhost:27017/"
MONGO_DB_NAME = "UniBridge_vectors"

# --- Singleton Session Manager ---
_session_manager = SessionManager()

def get_session_manager() -> SessionManager:
    """
    Dependency provider for the SessionManager.
    Singleton instance to maintain state across API calls.
    """
    return _session_manager

def get_final_ranker() -> FinalRank:
    """
    Dependency provider for the FinalRank engine.
    """
    return FinalRank(
        mongo_conn_str=MONGO_CONNECTION_STRING, 
        db_name=MONGO_DB_NAME
    )