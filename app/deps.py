import os
import pymongo
from dotenv import load_dotenv
from .session_manager import SessionManager
from engine.final_rank import FinalRank

# --- Load environment variables from .env ---
load_dotenv()

# --- Configuration ---
MONGO_CONNECTION_STRING = os.environ["MONGO_CONNECTION_STRING"]
MONGO_DB_NAME = os.environ["MONGO_DB_NAME"]
SQL_CONNECTION_STRING = os.environ["SQL_CONNECTION_STRING"]

# --- Global MongoDB Client (Connection Pooling) ---
# This client is created once and reused across all requests
mongo_client = pymongo.MongoClient(MONGO_CONNECTION_STRING)
mongo_db = mongo_client[MONGO_DB_NAME]

def get_mongo_db():
    """
    Dependency provider for the MongoDB database.
    Reuses the global, thread-safe MongoClient pool.
    """
    return mongo_db

# --- Singleton Session Manager ---
_session_manager = SessionManager(
    mongo_uri=MONGO_CONNECTION_STRING,
    db_name=MONGO_DB_NAME
)

def get_session_manager() -> SessionManager:
    return _session_manager

def get_final_ranker() -> FinalRank:
    return FinalRank(
        mongo_conn_str=MONGO_CONNECTION_STRING, 
        db_name=MONGO_DB_NAME,
        sql_conn_str=SQL_CONNECTION_STRING
    )