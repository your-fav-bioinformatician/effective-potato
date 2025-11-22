from fastapi import APIRouter, HTTPException, Depends, Body
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import pyodbc
import pymongo
import datetime
from app.deps import get_final_ranker, MONGO_CONNECTION_STRING, MONGO_DB_NAME
from engine.final_rank import FinalRank

router = APIRouter()


# --- Models ---
class CredentialsRequest(BaseModel):
    user_id: int
    username: str
    password: str  # In production, hash this!


class RankingResponse(BaseModel):
    full_name: str
    description: str
    web: str
    score: float
    details: Dict[str, float]


class FeedbackRequest(BaseModel):
    user_id: int
    rating: int
    comment: Optional[str] = None


# --- Helpers ---
def get_sql_conn():
    return pyodbc.connect(
        "Driver={ODBC Driver 17 for SQL Server};"
        "Server=.\\SQLEXPRESS;"
        "Database=Unis_db;"
        "Trusted_Connection=yes;"
    )


# --- Routes ---

@router.post("/results", response_model=List[RankingResponse])
def get_results_and_signup(
        req: CredentialsRequest,
        ranker: FinalRank = Depends(get_final_ranker)
):
    """
    1. Updates the anonymous user_id with username/password (Registration).
    2. Generates and returns rankings.
    """
    conn = get_sql_conn()
    cursor = conn.cursor()

    try:
        # 1. Update User credentials
        # Check if username already taken (basic check)
        check_sql = "SELECT user_id FROM Users WHERE username = ? AND user_id != ?"
        cursor.execute(check_sql, (req.username, req.user_id))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Username already taken.")

        update_sql = """
                     UPDATE Users
                     SET username = ?, \
                         password = ?
                     WHERE user_id = ? \
                     """
        cursor.execute(update_sql, (req.username, req.password, req.user_id))

        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="User ID not found.")

        conn.commit()

        # 2. Generate Rankings
        # FinalRank engine pulls from SQL (updated user info) and Mongo (final vector)
        recommendations = ranker.generate_rankings(user_id=req.user_id)
        return recommendations

    except HTTPException as he:
        raise he
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()


@router.post("/feedback")
def submit_feedback(req: FeedbackRequest):
    """
    Saves user feedback to MongoDB after results are shown.
    """
    client = pymongo.MongoClient(MONGO_CONNECTION_STRING)
    db = client[MONGO_DB_NAME]

    try:
        feedback_doc = {
            "user_id": req.user_id,
            "rating": req.rating,
            "comment": req.comment,
            "timestamp": datetime.datetime.utcnow()
        }
        db["User_Feedback"].insert_one(feedback_doc)
        return {"message": "Feedback received."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        client.close()