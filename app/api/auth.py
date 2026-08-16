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
    user_id: Optional[str] = None # Added to support upgrading guest profiles
    username: str
    email: str
    password: str

class LoginRequest(BaseModel):
    email: str
    password: str

class SessionRequest(BaseModel):
    user_id: str


@router.post("/signup")
def signup(req: SignupRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Creates a new user profile or upgrades a guest profile."""
    if db["users_data"].find_one({"email": req.email}):
        raise HTTPException(status_code=400, detail="Email already registered.")
    if db["users_data"].find_one({"username": req.username}):
        raise HTTPException(status_code=400, detail="Username already taken.")

    hashed_pw = hash_password(req.password)
    
    # If the user is already a guest, upgrade their profile
    if req.user_id:
        try:
            query = {"_id": ObjectId(req.user_id)}
        except Exception:
            query = {"user_id": req.user_id}
            
        result = db["users_data"].update_one(query, {"$set": {
            "username": req.username,
            "email": req.email,
            "password": hashed_pw,
            "session_active": True
        }})
        
        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Guest profile not found.")
        user_id_str = req.user_id
    else:
        # Standard signup (from the initial splash screen)
        user_doc = {
            "username": req.username,
            "email": req.email,
            "password": hashed_pw,
            "session_active": True
        }
        result = db["users_data"].insert_one(user_doc)
        user_id_str = str(result.inserted_id)

    mgr.create_session(user_id_str, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
    return {"message": "Account created successfully.", "user_id": user_id_str, "username": req.username}

@router.post("/login")
def login(req: LoginRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Verifies credentials and activates session persistence."""
    user = db["users_data"].find_one({"email": req.email})
    if not user or not user.get("password") or not verify_password(req.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    user_id_str = str(user["_id"])
    mgr.create_session(user_id_str, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
    
    return {"message": "Login successful.", "user_id": user_id_str, "username": user["username"]}

@router.post("/logout")
def logout(req: SessionRequest, mgr: SessionManager = Depends(get_session_manager)):
    mgr.end_session(req.user_id)
    return {"message": "Logged out successfully."}