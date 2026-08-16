import datetime
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId

from app.deps import get_session_manager, get_mongo_db
from app.session_manager import SessionManager

router = APIRouter()

class UserInfoRequest(BaseModel):
    user_id: Optional[str] = None
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

class AnswerRequest(BaseModel):
    user_id: str
    answer: int

def _get_mbti_template_vector(mbti_type: str, db):
    doc = db["mbti_vectors"].find_one({"mbti": {"$regex": f"^{mbti_type}$", "$options": "i"}})
    return doc["mbti_vector"] if doc else []

@router.post("/init", response_model=InitResponse)
def initialize_user(
        req: UserInfoRequest,
        mgr: SessionManager = Depends(get_session_manager),
        db = Depends(get_mongo_db)
):
    timestamp = str(datetime.datetime.utcnow())
    try:
        demographic_data = {
            "age": req.age, "gender": req.gender, "income": req.income,
            "city": req.city, "religion": req.religion, "language": req.language,
            "gpa": req.gpa, "hs_type": req.hs, "mbti": req.mbti,
            "career_goal": req.career_goal, "app_version": req.app_version,
            "lat": req.lat, "lon": req.lon, "prefer_close": req.prefer_close,
            "created_at": timestamp,
        }

        if req.user_id:
            # Append to pre-authenticated user
            try:
                query = {"_id": ObjectId(req.user_id)}
            except:
                query = {"user_id": req.user_id}
            db["users_data"].update_one(query, {"$set": demographic_data})
            user_id_str = req.user_id
        else:
            # Initialize as a strict Guest profile
            demographic_data.update({
                "username": None,
                "email": None,
                "password": None,
                "session_active": True
            })
            result = db["users_data"].insert_one(demographic_data)
            user_id_str = str(result.inserted_id)

        mbti_vec = _get_mbti_template_vector(req.mbti, db)

        db["User_vectors"].update_one(
            {"user_id": user_id_str},
            {"$set": {
                "mbti_vector": mbti_vec, "current_user_vector": mbti_vec, 
                "answers": [], "created_at": timestamp
            }},
            upsert=True
        )

        mgr.create_session(user_id_str, mgr.mongo_uri, mgr.db_name)
        return {"user_id": user_id_str, "message": "User initialized."}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/next_q")
def get_next_question(user_id: str, mgr: SessionManager = Depends(get_session_manager)):
    session = mgr.get_session(user_id)
    if not session:
        raise HTTPException(status_code=400, detail="Session expired.")
    result = session["calc"].run_optimization_step()
    if result.get("status") == "completed":
        mgr.end_session(user_id)
    return result

@router.post("/process_a")
def process_answer(payload: AnswerRequest, mgr: SessionManager = Depends(get_session_manager)):
    session = mgr.get_session(payload.user_id)
    if not session:
        raise HTTPException(status_code=400, detail="Session expired.")
    session["generator"].process_answer(payload.answer)
    return {"message": "Answer processed successfully", "user_id": payload.user_id}