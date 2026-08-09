from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId
from app.deps import get_session_manager, get_mongo_db, MONGO_CONNECTION_STRING, MONGO_DB_NAME
from app.session_manager import SessionManager
from app.security import hash_password, verify_password

router = APIRouter()

# --- Request Models ---
class SignupRequest(BaseModel):
    user_id: str
    username: str
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

class SessionRequest(BaseModel):
    user_id: str


@router.post("/signup")
def signup(req: SignupRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Links user credentials to the initialized profile and activates session."""
    # Check if username exists
    existing_user = db["users_data"].find_one({"username": req.username})
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already taken.")

    hashed_pw = hash_password(req.password)
    
    try:
        query = {"_id": ObjectId(req.user_id)}
    except Exception:
        query = {"user_id": req.user_id}

    result = db["users_data"].update_one(
        query,
        {"$set": {
            "username": req.username, 
            "password": hashed_pw, 
            "session_active": True
        }}
    )

    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User profile not found. Complete initialization first.")

    # Initialize active session state
    mgr.create_session(req.user_id, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
    return {"message": "Account created successfully.", "user_id": req.user_id, "username": req.username}


@router.post("/login")
def login(req: LoginRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Verifies credentials and activates session persistence."""
    user = db["users_data"].find_one({"username": req.username})
    if not user or not user.get("password") or not verify_password(req.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid username or password.")

    user_id_str = str(user["_id"])
    mgr.create_session(user_id_str, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
    
    return {
        "message": "Login successful.",
        "user_id": user_id_str,
        "username": user["username"]
    }


@router.post("/logout")
def logout(req: SessionRequest, mgr: SessionManager = Depends(get_session_manager)):
    """Ends the user session in MongoDB."""
    mgr.end_session(req.user_id)
    return {"message": "Logged out successfully."}


@router.get("/verify/{user_id}")
def verify_session(user_id: str, mgr: SessionManager = Depends(get_session_manager)):
    """Checks whether a stored session is still valid/active."""
    is_active = mgr._is_active_session(user_id)
    if not is_active:
        raise HTTPException(status_code=401, detail="Session expired or invalid.")
    return {"status": "active", "user_id": user_id}