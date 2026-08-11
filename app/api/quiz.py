# app/api/quiz.py
import datetime
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional

# Utilizing your exact dependency injection setup
from app.deps import get_session_manager, get_mongo_db
from app.session_manager import SessionManager

router = APIRouter()

# --- PYDANTIC SCHEMAS ---
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
    prefer_close: bool = False

class InitResponse(BaseModel):
    user_id: str
    message: str

# Fixes the Flutter "Failed to fetch" error
class AnswerRequest(BaseModel):
    user_id: str
    answer: int


def _get_mbti_template_vector(mbti_type: str, db):
    doc = db["mbti_vectors"].find_one({"mbti": {"$regex": f"^{mbti_type}$", "$options": "i"}})
    return doc["mbti_vector"] if doc else []


# --- ROUTES ---

@router.post("/init", response_model=InitResponse)
def initialize_user(
        req: UserInfoRequest,
        mgr: SessionManager = Depends(get_session_manager),
        db = Depends(get_mongo_db)
):
    print(f"Received Init Request for: {req.career_goal}")
    timestamp = str(datetime.datetime.utcnow())

    try:
        user_doc = {
            "age": req.age,
            "gender": req.gender,
            "income": req.income,
            "city": req.city,
            "religion": req.religion,
            "language": req.language,
            "gpa": req.gpa,
            "hs_type": req.hs,
            "mbti": req.mbti,
            "career_goal": req.career_goal,
            "app_version": req.app_version,
            "lat": req.lat,
            "lon": req.lon,
            "prefer_close": req.prefer_close,
            "created_at": timestamp,
            "username": None,
            "password": None,
            "session_active": True  # Initializes the flag for your SessionManager
        }

        result = db["users_data"].insert_one(user_doc)
        user_id_str = str(result.inserted_id)

        mbti_vec = _get_mbti_template_vector(req.mbti, db)

        db["User_vectors"].insert_one({
            "user_id": user_id_str,
            "mbti_vector": mbti_vec,
            "current_user_vector": mbti_vec, # Setup for intermediate saves
            "answers": [],                   # Setup for intermediate saves
            "created_at": timestamp
        })

        mgr.create_session(user_id_str, mgr.mongo_uri, mgr.db_name)
        return {"user_id": user_id_str, "message": "User initialized."}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/next_q")
def get_next_question(
        user_id: str, 
        mgr: SessionManager = Depends(get_session_manager)
):
    # Reconstructs session from DB
    session = mgr.get_session(user_id)
    if not session:
        raise HTTPException(status_code=400, detail="Session expired or invalid user_id.")
        
    entropy_engine = session["calc"]
    result = entropy_engine.run_optimization_step()
    
    if result.get("status") == "completed":
        mgr.end_session(user_id)
        
    return result


@router.post("/process_a")
def process_answer(
        payload: AnswerRequest, 
        mgr: SessionManager = Depends(get_session_manager)
):
    # Reconstructs session from DB
    session = mgr.get_session(payload.user_id)
    if not session:
        raise HTTPException(status_code=400, detail="Session expired or invalid user_id.")
    
    user_gen = session["generator"]
    
    # Process the answer
    user_gen.process_answer(payload.answer)
    
    return {"message": "Answer processed successfully", "user_id": payload.user_id}