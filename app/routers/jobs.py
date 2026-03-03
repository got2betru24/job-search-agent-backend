from fastapi import APIRouter, HTTPException
from typing import List, Optional
from app.models import JobResponse, JobStatusUpdate, JobStatus
from app.database import get_cursor

router = APIRouter(prefix="/jobs", tags=["jobs"])

@router.get("", response_model=List[JobResponse])
async def list_jobs(
    status: Optional[JobStatus] = None,
    role: Optional[str] = None,
):
    """
    Return jobs for the feed.
    Excludes archived jobs unless status=archived is explicitly requested.
    """
    with get_cursor() as cursor:
        conditions = []
        params = []

        if status:
            conditions.append("status = %s")
            params.append(status.value)
        else:
            # Default: hide archived from the feed
            conditions.append("status != %s")
            params.append("archived")

        if role:
            conditions.append("role = %s")
            params.append(role)

        where = f"WHERE {' AND '.join(conditions)}" if conditions else ""
        cursor.execute(
            f"SELECT * FROM jobs {where} ORDER BY found_at DESC",
            params
        )
        rows = cursor.fetchall()

    return [_parse_job(row) for row in rows]


@router.get("/{job_id}", response_model=JobResponse)
async def get_job(job_id: int):
    with get_cursor() as cursor:
        cursor.execute("SELECT * FROM jobs WHERE id = %s", (job_id,))
        row = cursor.fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Job not found")

    return _parse_job(row)


@router.patch("/{job_id}/status", response_model=JobResponse)
async def update_job_status(job_id: int, body: JobStatusUpdate):
    with get_cursor() as cursor:
        cursor.execute(
            "UPDATE jobs SET status = %s WHERE id = %s",
            (body.status.value, job_id)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Job not found")

        cursor.execute("SELECT * FROM jobs WHERE id = %s", (job_id,))
        row = cursor.fetchone()

    return _parse_job(row)


def _parse_job(row: dict) -> dict:
    """Parse JSON fields from DB row."""
    import json
    if row.get("requirements") and isinstance(row["requirements"], str):
        row["requirements"] = json.loads(row["requirements"])
    return row
