import datetime
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId

from app.deps import get_session_manager, get_mongo_db
from app.session_manager import SessionManager

router = APIRouter()

# --- PYDANTIC SCHEMAS ---
class UserInfoRequest(BaseModel):
    user_id: Optional[str] = None  # Passed if user signed in prior to initializing test
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
    is_guest: bool
    message: str

class AnswerRequest(BaseModel):
    user_id: str
    answer: int


def _get_mbti_template_vector(mbti_type: str, db):
    try:
        doc = db["mbti_vectors"].find_one({"mbti": {"$regex": f"^{mbti_type}$", "$options": "i"}})
        return doc["mbti_vector"] if doc else [0.5] * 10
    except Exception:
        return [0.5] * 10


# --- ROUTES ---

@router.post("/init", response_model=InitResponse)
def initialize_user(
        req: UserInfoRequest,
        mgr: SessionManager = Depends(get_session_manager),
        db = Depends(get_mongo_db)
):
    timestamp = str(datetime.datetime.utcnow())
    is_guest = True
    user_id_str = req.user_id

    # Check if user was already signed in
    if req.user_id:
        try:
            existing = db["users_data"].find_one({"_id": ObjectId(req.user_id)})
            if existing and existing.get("username"):
                is_guest = False
        except Exception:
            pass

    try:
        profile_data = {
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
            "is_guest": is_guest,
            "session_active": True
        }

        if user_id_str and not is_guest:
            # Update existing signed-in account profile
            db["users_data"].update_one({"_id": ObjectId(user_id_str)}, {"$set": profile_data})
        else:
            # Guest initialization
            profile_data["username"] = None
            profile_data["password"] = None
            result = db["users_data"].insert_one(profile_data)
            user_id_str = str(result.inserted_id)

        mbti_vec = _get_mbti_template_vector(req.mbti, db)

        db["User_vectors"].update_one(
            {"user_id": user_id_str},
            {"$set": {
                "mbti_vector": mbti_vec,
                "current_user_vector": mbti_vec,
                "answers": [],
                "created_at": timestamp
            }},
            upsert=True
        )

        mgr.create_session(user_id_str, mgr.mongo_uri, mgr.db_name)
        return {
            "user_id": user_id_str, 
            "is_guest": is_guest, 
            "message": "User test initialized."
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/next_q")
def get_next_question(
        user_id: str, 
        mgr: SessionManager = Depends(get_session_manager),
        db = Depends(get_mongo_db)
):
    session = mgr.get_session(user_id)
    
    # Mock / engine question retrieval
    try:
        if session:
            entropy_engine = session["calc"]
            result = entropy_engine.run_optimization_step()
        else:
            # Fallback mock question sequence
            result = {
                "status": "active",
                "layer": 1,
                "question_data": {"question": "Do you prefer analytical problem solving or creative design?"}
            }
    except Exception:
        result = {
            "status": "completed"
        }

    # When test completes, check if authentication is required
    if result.get("status") == "completed":
        mgr.end_session(user_id)
        
        # Check user auth status
        user = db["users_data"].find_one({"_id": ObjectId(user_id)}) if ObjectId.is_valid(user_id) else None
        is_guest = user.get("is_guest", True) if user else True
        
        return {
            "status": "completed",
            "requires_auth": is_guest,  # True if guest needs to sign up/in; False if already signed in
            "user_id": user_id
        }
        
    return result


@router.post("/process_a")
def process_answer(
        payload: AnswerRequest, 
        mgr: SessionManager = Depends(get_session_manager)
):
    session = mgr.get_session(payload.user_id)
    if session:
        try:
            user_gen = session["generator"]
            user_gen.process_answer(payload.answer)
        except Exception:
            pass
            
    return {"message": "Answer processed successfully", "user_id": payload.user_id}