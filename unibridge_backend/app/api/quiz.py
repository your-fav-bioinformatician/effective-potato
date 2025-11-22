from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
import datetime
import pyodbc
import pymongo

from app.deps import get_session_manager, MONGO_CONNECTION_STRING, MONGO_DB_NAME
from app.session_manager import SessionManager

router = APIRouter()


# --- Models ---
class UserInfoRequest(BaseModel):
    age: int
    gender: str
    income: str
    city: str
    religion: str
    language: str
    gpa: float
    hs: str
    mbti: str
    career_goal: str
    app_version: str
    lat: Optional[float] = None
    lon: Optional[float] = None
    prefer_close: Optional[bool] = False


class InitResponse(BaseModel):
    user_id: int
    message: str


class AnswerRequest(BaseModel):
    user_id: int
    answer: int


# --- Helper ---
def get_sql_conn():
    drivers = [
        "{ODBC Driver 17 for SQL Server}",
        "{ODBC Driver 18 for SQL Server}",
        "{SQL Server}"
    ]
    for driver in drivers:
        try:
            conn_str = (
                f"Driver={driver};"
                "Server=.\\SQLEXPRESS;"
                "Database=Users_db;"
                "Trusted_Connection=yes;"
                "TrustServerCertificate=yes;"
            )
            return pyodbc.connect(conn_str)
        except:
            continue
    raise Exception("Could not connect to SQL Server.")


def _get_mbti_template_vector(mbti_type: str, db) -> list:
    return [0.0] * 768


# --- Routes ---

@router.post("/init", response_model=InitResponse)
def initialize_user(
        req: UserInfoRequest,
        mgr: SessionManager = Depends(get_session_manager)
):
    print(f"Received Init Request for: {req.career_goal}")
    timestamp = str(datetime.datetime.utcnow() + datetime.timedelta(hours=3))

    conn = None
    try:
        conn = get_sql_conn()
        cursor = conn.cursor()

        # EXPLICIT SCHEMA: [dbo].[Users]
        query = """
                INSERT INTO [dbo].[Users] (age, gender, income, city, religion, language, gpa, hs_type, mbti, \
                                           career_goal, app_version, lat, lon, created_at)
                OUTPUT INSERTED.user_id
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) \
                """
        values = (req.age, req.gender, req.income, req.city, req.religion, req.language,
                  req.gpa, req.hs, req.mbti, req.career_goal, req.app_version, req.lat, req.lon, timestamp)

        cursor.execute(query, values)
        row = cursor.fetchone()
        if not row: raise HTTPException(status_code=500, detail="Failed to retrieve ID.")

        user_id = row[0]
        conn.commit()

        # Mongo
        mongo_client = pymongo.MongoClient(MONGO_CONNECTION_STRING)
        db = mongo_client[MONGO_DB_NAME]
        mbti_vec = _get_mbti_template_vector(req.mbti, db)
        db["User_vectors"].update_one(
            {"user_id": user_id},
            {"$set": {"mbti_vector": mbti_vec, "created_at": timestamp}},
            upsert=True
        )
        mongo_client.close()

        mgr.create_session(user_id, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
        return {"user_id": user_id, "message": "User initialized."}

    except Exception as e:
        print(f"INIT ERROR: {str(e)}")
        if conn: conn.rollback()
        raise HTTPException(status_code=500, detail=f"Initialization failed: {str(e)}")
    finally:
        if conn: conn.close()


@router.get("/next_q")
def get_next_question(user_id: int, mgr: SessionManager = Depends(get_session_manager)):
    session = mgr.get_session(user_id)
    if not session: raise HTTPException(status_code=404, detail="Session not found.")
    try:
        step = session["calc"].run_optimization_step()
        if step["status"] == "completed": mgr.end_session(user_id)
        return step
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/process_a")
def process_answer(req: AnswerRequest, mgr: SessionManager = Depends(get_session_manager)):
    session = mgr.get_session(req.user_id)
    if not session: raise HTTPException(status_code=404, detail="Session not found.")
    try:
        session["generator"].process_answer(req.answer)
        if session["generator"].is_active_question_final:
            mgr.end_session(req.user_id)
            return {"status": "session_completed"}
        return {"status": "continue"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))