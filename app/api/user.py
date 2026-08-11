from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from bson import ObjectId
from app.deps import get_mongo_db

router = APIRouter()

# --- Schemas ---
class UserProfileUpdate(BaseModel):
    user_id: str
    age: Optional[int] = None
    gpa: Optional[float] = None
    city: Optional[str] = None
    career_goal: Optional[str] = None
    mbti: Optional[str] = None

class BookmarkItem(BaseModel):
    user_id: str
    item_id: str
    item_type: str  # "major" or "university"
    title: str

# --- Mock Fallbacks for Bookmarks/History ---
MOCK_BOOKMARKS = [
    {"item_id": "m1", "item_type": "major", "title": "Software & AI Engineering"},
    {"item_id": "u3", "item_type": "university", "title": "University of Technology - Baghdad"}
]

MOCK_HISTORY = [
    {
        "test_id": "t_01",
        "date": "2026-08-01",
        "top_match": "Software & AI Engineering",
        "match_percentage": 95
    },
    {
        "test_id": "t_02",
        "date": "2026-06-15",
        "top_match": "Data Science & Cyber Analytics",
        "match_percentage": 89
    }
]

# --- Routes ---

@router.get("/profile/{user_id}")
def get_profile(user_id: str, db = Depends(get_mongo_db)):
    """Retrieves current user profile information."""
    try:
        user = db["users_data"].find_one({"_id": ObjectId(user_id)})
    except Exception:
        user = db["users_data"].find_one({"user_id": user_id})

    if not user:
        raise HTTPException(status_code=404, detail="User profile not found.")

    return {
        "user_id": str(user.get("_id", user_id)),
        "username": user.get("username", "Guest"),
        "is_guest": user.get("is_guest", True),
        "age": user.get("age", 18),
        "gpa": user.get("gpa", 3.5),
        "city": user.get("city", "Baghdad"),
        "mbti": user.get("mbti", "INTJ"),
        "career_goal": user.get("career_goal", "Software Engineering"),
        "created_at": user.get("created_at", "N/A")
    }


@router.put("/profile")
def update_profile(req: UserProfileUpdate, db = Depends(get_mongo_db)):
    """Updates user demographic preferences and info."""
    update_data = {k: v for k, v in req.dict().items() if v is not None and k != "user_id"}
    
    if not update_data:
        return {"message": "No fields to update."}

    try:
        query = {"_id": ObjectId(req.user_id)}
    except Exception:
        query = {"user_id": req.user_id}

    result = db["users_data"].update_one(query, {"$set": update_data})
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="User not found.")

    return {"message": "Profile updated successfully.", "updated_fields": list(update_data.keys())}


@router.get("/bookmarks/{user_id}")
def get_bookmarks(user_id: str, db = Depends(get_mongo_db)):
    """Returns all bookmarked majors and universities for a user."""
    try:
        user = db["users_data"].find_one({"_id": ObjectId(user_id)})
        if user and "bookmarks" in user:
            return user["bookmarks"]
    except Exception:
        pass

    return MOCK_BOOKMARKS


@router.post("/bookmarks")
def add_bookmark(item: BookmarkItem, db = Depends(get_mongo_db)):
    """Saves a major or university to user's saved collection."""
    bookmark_entry = {
        "item_id": item.item_id,
        "item_type": item.item_type,
        "title": item.title
    }

    try:
        query = {"_id": ObjectId(item.user_id)}
    except Exception:
        query = {"user_id": item.user_id}

    db["users_data"].update_one(
        query,
        {"$addToSet": {"bookmarks": bookmark_entry}},
        upsert=True
    )

    return {"message": f"Saved '{item.title}' to bookmarks."}


@router.delete("/bookmarks/{user_id}/{item_id}")
def remove_bookmark(user_id: str, item_id: str, db = Depends(get_mongo_db)):
    """Removes an item from user bookmarks."""
    try:
        query = {"_id": ObjectId(user_id)}
    except Exception:
        query = {"user_id": user_id}

    db["users_data"].update_one(
        query,
        {"$pull": {"bookmarks": {"item_id": item_id}}}
    )

    return {"message": "Bookmark removed."}


@router.get("/history/{user_id}")
def get_assessment_history(user_id: str, db = Depends(get_mongo_db)):
    """Retrieves user's historical assessment runs."""
    try:
        user = db["users_data"].find_one({"_id": ObjectId(user_id)})
        if user and "history" in user:
            return user["history"]
    except Exception:
        pass

    return MOCK_HISTORY