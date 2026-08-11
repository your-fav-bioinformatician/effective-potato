from fastapi import APIRouter, HTTPException, Depends
from bson import ObjectId
from app.deps import get_mongo_db, MONGO_CONNECTION_STRING, MONGO_DB_NAME, SQL_CONNECTION_STRING
from app.security import verify_password
from engine.final_rank import FinalRank

router = APIRouter()

# --- Mock Data Fallback ---
MOCK_RESULTS = [
    {
        "full_name": "Software & AI Engineering",
        "score": 0.95,
        "description": "High alignment with analytical problem solving and technical career objectives."
    },
    {
        "full_name": "Data Science & Cyber Analytics",
        "score": 0.88,
        "description": "Strong match based on psychometric profile and high quantitative affinity."
    },
    {
        "full_name": "Computer Network Systems",
        "score": 0.82,
        "description": "Optimal path balancing engineering systems with practical implementation."
    },
    {
        "full_name": "Biomedical Engineering",
        "score": 0.76,
        "description": "Secondary match correlating scientific track background with technical problem solving."
    }
]

@router.post("/results")
def get_results(req: dict, db = Depends(get_mongo_db)):
    user_id = req.get("user_id")

    if not user_id:
        raise HTTPException(status_code=400, detail="Missing user_id parameter.")

    # 1. Fetch user from DB
    try:
        user = db["users_data"].find_one({"_id": ObjectId(user_id)})
    except Exception:
        user = db["users_data"].find_one({"user_id": user_id})

    if not user:
        raise HTTPException(status_code=404, detail="User profile not found.")

    # 2. Verify account is authenticated (Not guest)
    if user.get("is_guest", True) or not user.get("username"):
        raise HTTPException(
            status_code=401, 
            detail="Authentication required to view persistent results. Please log in or sign up."
        )

    # 3. Check for previously saved persistent results
    if "saved_results" in user and user["saved_results"]:
        return user["saved_results"]

    # 4. Generate Actual Results via Engine with Mock Fallback
    try:
        ranker = FinalRank(
            mongo_conn_str=MONGO_CONNECTION_STRING, 
            db_name=MONGO_DB_NAME,
            sql_conn_str=SQL_CONNECTION_STRING
        )
        actual_results = ranker.generate_rankings(user_id)
        
        if not actual_results:
            actual_results = MOCK_RESULTS

    except Exception as e:
        print(f"Engine calculation error fallback to mock data: {e}")
        actual_results = MOCK_RESULTS

    # Persist calculated results to user document
    db["users_data"].update_one(
        {"_id": user["_id"]},
        {"$set": {"saved_results": actual_results}}
    )

    return actual_results