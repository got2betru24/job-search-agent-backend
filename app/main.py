from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import jobs, resumes, sources, scraper
import os

app = FastAPI(
    root_path="/api",
    title="Job Search Agent API",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ──────────────────────────────────────────────────
app.include_router(jobs.router)
app.include_router(resumes.router)
app.include_router(sources.router)
app.include_router(scraper.router)

# ── Health ───────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "healthy"}
