from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from pydantic import BaseModel

router = APIRouter()

# --- Schemas ---
class MajorSummary(BaseModel):
    id: str
    title: str
    category: str
    match_score: Optional[float] = None
    duration_years: int
    avg_salary_usd: int

class MajorDetail(BaseModel):
    id: str
    title: str
    category: str
    description: str
    duration_years: int
    avg_salary_usd: int
    key_skills: List[str]
    career_paths: List[str]
    top_universities: List[str]

class UniversitySummary(BaseModel):
    id: str
    name: str
    city: str
    country: str
    type: str  # Public / Private
    tuition_per_year_usd: int
    rating: float

# --- Mock Datasets ---
MOCK_MAJORS_DB = [
    {
        "id": "m1",
        "title": "Software & AI Engineering",
        "category": "Technology",
        "description": "Focuses on designing intelligent software systems, machine learning models, and scalable modern web architecture.",
        "duration_years": 4,
        "avg_salary_usd": 85000,
        "key_skills": ["Python", "Algorithms", "System Architecture", "Neural Networks"],
        "career_paths": ["AI Researcher", "Full Stack Developer", "Data Architect"],
        "top_universities": ["Tech University of Baghdad", "Al-Mansour Institute of Technology"]
    },
    {
        "id": "m2",
        "title": "Data Science & Cyber Analytics",
        "category": "Technology",
        "description": "Combines statistical analysis, threat detection, and big data visualization to secure digital ecosystems.",
        "duration_years": 4,
        "avg_salary_usd": 78000,
        "key_skills": ["Cybersecurity", "SQL", "Statistical Modeling", "Cryptography"],
        "career_paths": ["Security Analyst", "Data Scientist", "Threat Intelligence Lead"],
        "top_universities": ["Baghdad University", "Al-Nahrain University"]
    },
    {
        "id": "m3",
        "title": "Biomedical Engineering",
        "category": "Healthcare",
        "description": "Bridges medicine and technology to engineer prosthetic devices, diagnostic tools, and medical software.",
        "duration_years": 5,
        "avg_salary_usd": 72000,
        "key_skills": ["Biomechanics", "Medical Imaging", "Signal Processing", "Tissue Engineering"],
        "career_paths": ["Biomedical Tech Lead", "Clinical Engineer", "Prosthetics Specialist"],
        "top_universities": ["Mustansiriyah University", "University of Technology"]
    },
    {
        "id": "m4",
        "title": "Renewable & Electrical Energy Systems",
        "category": "Engineering",
        "description": "Explores clean energy transition, smart grid design, and modern electrical infrastructure.",
        "duration_years": 4,
        "avg_salary_usd": 70000,
        "key_skills": ["Solar Grid Design", "Circuits", "Power Distribution", "MATLAB"],
        "career_paths": ["Solar Energy Engineer", "Power Systems Consultant", "Grid Operator"],
        "top_universities": ["University of Technology"]
    }
]

MOCK_UNIVERSITIES_DB = [
    {
        "id": "u1",
        "name": "University of Baghdad",
        "city": "Baghdad",
        "country": "Iraq",
        "type": "Public",
        "tuition_per_year_usd": 1200,
        "rating": 4.6
    },
    {
        "id": "u2",
        "name": "Al-Nahrain University",
        "city": "Baghdad",
        "country": "Iraq",
        "type": "Public",
        "tuition_per_year_usd": 1500,
        "rating": 4.5
    },
    {
        "id": "u3",
        "name": "University of Technology - Baghdad",
        "city": "Baghdad",
        "country": "Iraq",
        "type": "Public",
        "tuition_per_year_usd": 1100,
        "rating": 4.7
    }
]


# --- Routes ---

@router.get("/majors", response_model=List[MajorSummary])
def get_majors(
    search: Optional[str] = Query(None),
    category: Optional[str] = Query(None)
):
    """Browses or filters the catalog of academic majors."""
    results = MOCK_MAJORS_DB
    
    if search:
        s = search.lower()
        results = [m for m in results if s in m["title"].lower() or s in m["description"].lower()]
        
    if category:
        results = [m for m in results if m["category"].lower() == category.lower()]
        
    return results


@router.get("/majors/{major_id}", response_model=MajorDetail)
def get_major_details(major_id: str):
    """Retrieves full profile details for a specific major."""
    major = next((m for m in MOCK_MAJORS_DB if m["id"] == major_id), None)
    if not major:
        raise HTTPException(status_code=404, detail="Major not found.")
    return major


@router.get("/universities", response_model=List[UniversitySummary])
def get_universities(city: Optional[str] = Query(None)):
    """Retrieves list of universities, optionally filtered by location."""
    if city:
        return [u for u in MOCK_UNIVERSITIES_DB if u["city"].lower() == city.lower()]
    return MOCK_UNIVERSITIES_DB


@router.get("/universities/{uni_id}", response_model=UniversitySummary)
def get_university_details(uni_id: str):
    """Retrieves detailed university profile."""
    uni = next((u for u in MOCK_UNIVERSITIES_DB if u["id"] == uni_id), None)
    if not uni:
        raise HTTPException(status_code=404, detail="University not found.")
    return uni