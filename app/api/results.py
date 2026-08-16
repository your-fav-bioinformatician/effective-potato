from fastapi import APIRouter, HTTPException, Depends
from bson import ObjectId
from app.deps import get_mongo_db, MONGO_CONNECTION_STRING, MONGO_DB_NAME, SQL_CONNECTION_STRING
from engine.final_rank import FinalRank

router = APIRouter()

@router.post("/results")
def get_results(req: dict, db = Depends(get_mongo_db)):
    user_id = req.get("user_id")

    if not user_id:
        raise HTTPException(status_code=400, detail="Missing user_id in request.")

    # 1. Fetch user from DB
    try:
        user = db["users_data"].find_one({"_id": ObjectId(user_id)})
    except Exception:
        user = db["users_data"].find_one({"user_id": user_id})

    if not user:
        raise HTTPException(status_code=404, detail="User profile not found.")

    # 2. Gatekeeper: Check if user is a guest
    is_guest = not user.get("password") or not user.get("email")
    
    if is_guest:
        # A 403 tells the Flutter frontend to trigger the Guest Auth Flow
        raise HTTPException(
            status_code=403, 
            detail="Guest account detected. Please complete sign-up to view results."
        )

    # 3. User is Registered -> Return Results
    try:
        ranker = FinalRank(
            mongo_conn_str=MONGO_CONNECTION_STRING, 
            db_name=MONGO_DB_NAME,
            sql_conn_str=SQL_CONNECTION_STRING
        )
        
        actual_results = ranker.generate_rankings(user_id)
        return actual_results if actual_results else []
        
    except Exception as e:
        print(f"ERROR calculating final results: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate final rankings.")