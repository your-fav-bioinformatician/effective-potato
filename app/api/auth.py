import logging
import re
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, field_validator
from typing import Optional
from bson import ObjectId
from app.deps import get_session_manager, get_mongo_db, MONGO_CONNECTION_STRING, MONGO_DB_NAME
from app.session_manager import SessionManager
from app.security import hash_password, verify_password

router = APIRouter()
logger = logging.getLogger(__name__)

PASSWORD_RULE_MSG = "Password must be at least 8 characters and include an uppercase letter, a number, and a special character."

def _is_password_valid(password: str) -> bool:
    return (
        len(password) >= 8
        and re.search(r"[A-Z]", password) is not None
        and re.search(r"[0-9]", password) is not None
        and re.search(r"[!@#$%^&*(),.?\":{}|<>]", password) is not None
    )

class SignupRequest(BaseModel):
    user_id: Optional[str] = None
    username: str
    email: str
    password: str

    @field_validator("password")
    @classmethod
    def password_complexity(cls, v: str) -> str:
        if not _is_password_valid(v):
            raise ValueError(PASSWORD_RULE_MSG)
        return v

class LoginRequest(BaseModel):
    # Accept identifier as 'email' or 'username_or_email'
    email: Optional[str] = None
    username_or_email: Optional[str] = None
    password: str

class SessionRequest(BaseModel):
    user_id: str

@router.post("/signup")
def signup(req: SignupRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Creates a new user profile or upgrades a guest profile."""
    try:
        email_lower = req.email.lower().strip()
        username_lower = req.username.lower().strip()


        if db["users_data"].find_one({"email": {"$regex": f"^{re.escape(email_lower)}$", "$options": "i"}}):
            raise HTTPException(status_code=400, detail="Email already registered.")
        if db["users_data"].find_one({"username": {"$regex": f"^{re.escape(username_lower)}$", "$options": "i"}}):
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
                "email": email_lower,
                "password": hashed_pw,
                "session_active": True
            }})
            
            if result.matched_count == 0:
                logger.error(f"Guest profile {req.user_id} not found during upgrade.")
                raise HTTPException(status_code=404, detail="Guest profile not found.")
            user_id_str = req.user_id
        else:
            # Standard signup (from the initial splash screen)
            user_doc = {
                "username": req.username,
                "email": email_lower,
                "password": hashed_pw,
                "session_active": True
            }
            result = db["users_data"].insert_one(user_doc)
            user_id_str = str(result.inserted_id)

        mgr.create_session(user_id_str, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
        return {"message": "Account created successfully.", "user_id": user_id_str, "username": req.username}

    except HTTPException:
        raise
    except Exception as e:
        # logger.exception logs the full traceback, not just str(e) — this is
        # what was missing that made these failures show up nowhere.
        logger.exception("Signup error")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.post("/login")
def login(req: LoginRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Verifies credentials via Email OR Username and activates session persistence."""
    try:
        # Grab whichever identifier field was provided
        raw_identifier = req.username_or_email or req.email or ""
        identifier = raw_identifier.lower().strip()
        
        if not identifier:
            raise HTTPException(status_code=422, detail="Username or Email is required.")

        # Search MongoDB for EITHER email OR username (case-insensitive)
        query_regex = {"$regex": f"^{re.escape(identifier)}$", "$options": "i"}
        user = db["users_data"].find_one({
            "$or": [
                {"email": query_regex},
                {"username": query_regex}
            ]
        })
        
        if not user:
            raise HTTPException(status_code=401, detail="Invalid username/email or password.")
            
        if not user.get("password"):
            raise HTTPException(status_code=401, detail="Account is a guest profile. Please sign up to secure it.")

        if not verify_password(req.password, user["password"]):
            raise HTTPException(status_code=401, detail="Invalid username/email or password.")

        user_id_str = str(user["_id"])
        mgr.create_session(user_id_str, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
        
        return {"message": "Login successful.", "user_id": user_id_str, "username": user.get("username", "User")}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Login error")
        raise HTTPException(status_code=500, detail=f"An error occurred during login: {str(e)}")

@router.post("/logout")
def logout(req: SessionRequest, mgr: SessionManager = Depends(get_session_manager)):
    mgr.end_session(req.user_id)
    return {"message": "Logged out successfully."}

# ADDED: Essential for flutter's restoreSession logic on page reload
@router.get("/verify/{user_id}")
def verify_session(user_id: str, db = Depends(get_mongo_db)):
    try:
        try:
            query = {"_id": ObjectId(user_id)}
        except Exception:
            query = {"user_id": user_id}
        user = db["users_data"].find_one(query)
        
        if not user:
            raise HTTPException(status_code=404, detail="Session invalid")
        quiz_completed = user.get("session_active", True) is False
        return {"status": "valid", "quiz_completed": quiz_completed}
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("Verify session error")
        raise HTTPException(status_code=500, detail="Server error")