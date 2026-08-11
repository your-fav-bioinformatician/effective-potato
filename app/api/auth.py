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
    user_id: Optional[str] = None  # If passed, converts guest profile to permanent account
    username: str
    password: str

class LoginRequest(BaseModel):
    username: str
    password: str

class SessionRequest(BaseModel):
    user_id: str


@router.post("/signup")
def signup(req: SignupRequest, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """
    Supports standalone signup up front OR converting a guest session after test completion.
    """
    # 1. Check if username exists
    existing_user = db["users_data"].find_one({"username": req.username})
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already taken.")

    hashed_pw = hash_password(req.password)

    # 2. If converting an existing guest session
    if req.user_id:
        try:
            query = {"_id": ObjectId(req.user_id)}
        except Exception:
            query = {"user_id": req.user_id}

        result = db["users_data"].update_one(
            query,
            {"$set": {
                "username": req.username, 
                "password": hashed_pw, 
                "is_guest": False,
                "session_active": True
            }}
        )

        if result.matched_count > 0:
            mgr.create_session(req.user_id, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
            return {
                "message": "Guest profile converted to permanent account successfully.",
                "user_id": req.user_id,
                "username": req.username,
                "is_authenticated": True
            }

    # 3. Up-front Signup (No prior guest session)
    new_user = {
        "username": req.username,
        "password": hashed_pw,
        "is_guest": False,
        "session_active": True,
        "created_at": "now"
    }
    
    insert_res = db["users_data"].insert_one(new_user)
    user_id_str = str(insert_res.inserted_id)

    mgr.create_session(user_id_str, MONGO_CONNECTION_STRING, MONGO_DB_NAME)
    
    return {
        "message": "Account created successfully.",
        "user_id": user_id_str,
        "username": req.username,
        "is_authenticated": True
    }


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
        "username": user["username"],
        "is_authenticated": True
    }


@router.post("/logout")
def logout(req: SessionRequest, mgr: SessionManager = Depends(get_session_manager)):
    """Ends the user session."""
    mgr.end_session(req.user_id)
    return {"message": "Logged out successfully."}


@router.get("/verify/{user_id}")
def verify_session(user_id: str, db = Depends(get_mongo_db), mgr: SessionManager = Depends(get_session_manager)):
    """Checks whether a stored session is authenticated or guest."""
    try:
        user = db["users_data"].find_one({"_id": ObjectId(user_id)})
    except Exception:
        user = db["users_data"].find_one({"user_id": user_id})

    if not user:
        return {"status": "guest", "is_authenticated": False}

    is_authenticated = not user.get("is_guest", True) and user.get("username") is not None
    return {
        "status": "active" if is_authenticated else "guest",
        "user_id": user_id,
        "username": user.get("username"),
        "is_authenticated": is_authenticated
    }