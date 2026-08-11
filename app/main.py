import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import quiz, results, auth, majors, user

app = FastAPI(
    title="UniBridge Backend API", 
    description="Unified API endpoints for Auth, Quiz Engine, Major Matching, and User Portals",
    version="1.2.0"
)

# --- CORS Middlewares ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Include Application Routers ---
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(quiz.router, prefix="/quiz", tags=["Quiz Engine"])
app.include_router(results.router, prefix="/results", tags=["Results & Analysis"])
app.include_router(majors.router, prefix="/catalog", tags=["Majors & Universities"])
app.include_router(user.router, prefix="/user", tags=["User Profile & Bookmarks"])

@app.get("/")
def root():
    return {
        "system": "UniBridge Backend API",
        "status": "operational",
        "version": "1.2.0"
    }

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)