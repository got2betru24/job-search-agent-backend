from fastapi import APIRouter, HTTPException
from typing import List
from app.models import ResumeResponse, ResumeUpdate
from app.database import get_cursor

router = APIRouter(prefix="/resumes", tags=["resumes"])

@router.get("", response_model=List[ResumeResponse])
async def list_resumes():
    with get_cursor() as cursor:
        cursor.execute(
            "SELECT * FROM resumes ORDER BY is_base DESC, role ASC, created_at DESC"
        )
        rows = cursor.fetchall()
    return rows


@router.get("/{resume_id}", response_model=ResumeResponse)
async def get_resume(resume_id: int):
    with get_cursor() as cursor:
        cursor.execute("SELECT * FROM resumes WHERE id = %s", (resume_id,))
        row = cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Resume not found")
    return row


@router.patch("/{resume_id}", response_model=ResumeResponse)
async def update_resume(resume_id: int, body: ResumeUpdate):
    """Update name and/or content of a resume."""
    fields = {k: v for k, v in body.model_dump().items() if v is not None}
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")

    set_clause = ", ".join(f"{k} = %s" for k in fields)
    with get_cursor() as cursor:
        cursor.execute(
            f"UPDATE resumes SET {set_clause} WHERE id = %s",
            (*fields.values(), resume_id)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Resume not found")
        cursor.execute("SELECT * FROM resumes WHERE id = %s", (resume_id,))
        row = cursor.fetchone()
    return row


@router.get("/job/{job_id}", response_model=ResumeResponse)
async def get_tailored_resume_for_job(job_id: int):
    """Get the tailored resume for a specific job if one exists."""
    with get_cursor() as cursor:
        cursor.execute(
            "SELECT * FROM resumes WHERE job_id = %s AND is_base = FALSE",
            (job_id,)
        )
        row = cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="No tailored resume found for this job")
    return row
