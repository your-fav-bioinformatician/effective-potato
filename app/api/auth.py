import logging
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId
from app.deps import get_session_manager, get_mongo_db, MONGO_CONNECTION_STRING, MONGO_DB_NAME
from app.session_manager import SessionManager
from app.security import hash_password, verify_password

router = APIRouter()
logger = logging.getLogger(__name__)

class SignupRequest(BaseModel):
    user_id: Optional[str] = None
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
    try:
        email_lower = req.email.lower().strip()
        username_lower = req.username.lower().strip()

        # Case-insensitive checks for existing emails/usernames
        if db["users_data"].find_one({"email": {"$regex": f"^{email_lower}$", "$options": "i"}}):
            raise HTTPException(status_code=400, detail="Email already registered.")
        if db["users_data"].find_one({"username": {"$regex": f"^{username_lower}$", "$options": "i"}}):
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
        logger.error(f"Signup error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@router.post("/login")
def login(req: LoginRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Verifies credentials and activates session persistence."""
    try:
        email_lower = req.email.lower().strip()
        user = db["users_data"].find_one({"email": {"$regex": f"^{email_lower}$", "$options": "i"}})
        
        if not user:
            raise HTTPException(status_code=401, detail="Invalid email or password.")
            
        if not user.get("password"):
            raise HTTPException(status_code=401, detail="Account is a guest profile. Please sign up to secure it.")

        if not verify_password(req.password, user["password"]):
            raise HTTPException(status_code=401, detail="Invalid email or password.")

        user_id_str = str(user["_id"])
        mgr.create_session(user_id_str, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
        
        return {"message": "Login successful.", "user_id": user_id_str, "username": user.get("username", "User")}
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"An error occurred during login.")

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
        return {"status": "valid"}
    except Exception as e:
        logger.error(f"Verify session error: {str(e)}")
        raise HTTPException(status_code=500, detail="Server error")