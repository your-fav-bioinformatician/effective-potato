from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Import Routers
from app.api import quiz, results

app = FastAPI(title="UniBridge Backend", version="1.0.0")

# --- CRITICAL CORS SETUP ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Essential for Flutter Web localhost
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Router Registration ---
app.include_router(quiz.router, prefix="/quiz", tags=["Quiz Engine"])
app.include_router(results.router, prefix="/results", tags=["Results & Auth"])

@app.get("/")
def root():
    return {"message": "UniBridge Backend API is running."}

if __name__ == "__main__":
    # Host 0.0.0.0 is required for Android Emulator access
    uvicorn.run(app, host="0.0.0.0", port=8080)