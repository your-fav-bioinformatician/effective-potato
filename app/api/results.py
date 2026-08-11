from fastapi import APIRouter, HTTPException, Depends
from bson import ObjectId
from app.deps import get_mongo_db, MONGO_CONNECTION_STRING, MONGO_DB_NAME, SQL_CONNECTION_STRING
from app.security import verify_password
from engine.final_rank import FinalRank

router = APIRouter()

@router.post("/results")
def get_results(req: dict, db = Depends(get_mongo_db)):
    user_id = req.get("user_id")
    username = req.get("username")
    password = req.get("password")

    # 1. Fetch user from DB
    try:
        user = db["users_data"].find_one({"_id": ObjectId(user_id)})
    except Exception:
        user = db["users_data"].find_one({"user_id": user_id})

    if not user:
        raise HTTPException(status_code=404, detail="User profile not found.")

    # 2. Check if user completed signup
    stored_hash = user.get("password")
    if not stored_hash:
        raise HTTPException(
            status_code=400, 
            detail="User account has not been registered yet. Complete signup first."
        )

    # 3. Verify credentials safely
    if not verify_password(password, stored_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password.")

    # 4. Generate Actual Results using the FinalRank Engine
    try:
        # Pass the connection strings from your deps to ensure it points to the right DB
        ranker = FinalRank(
            mongo_conn_str=MONGO_CONNECTION_STRING, 
            db_name=MONGO_DB_NAME,
            sql_conn_str=SQL_CONNECTION_STRING
        )
        
        # Calculate the top 5 matches
        actual_results = ranker.generate_rankings(user_id)
        
        if not actual_results:
            # Fallback if the user somehow filtered out every single major in existence
            return []
            
        return actual_results
        
    except Exception as e:
        print(f"ERROR calculating final results: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate final rankings.")