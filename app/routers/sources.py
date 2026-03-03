from fastapi import APIRouter, HTTPException
from typing import List
from app.models import SourceResponse, SourceCreate
from app.database import get_cursor
import json

router = APIRouter(prefix="/sources", tags=["sources"])

@router.get("", response_model=List[SourceResponse])
async def list_sources():
    with get_cursor() as cursor:
        cursor.execute("SELECT * FROM sources ORDER BY company ASC")
        rows = cursor.fetchall()
    return [_parse_source(row) for row in rows]


@router.post("", response_model=SourceResponse, status_code=201)
async def create_source(body: SourceCreate):
    with get_cursor() as cursor:
        cursor.execute(
            """INSERT INTO sources (company, url, active, filters, requires_js)
               VALUES (%s, %s, %s, %s, %s)""",
            (
                body.company,
                body.url,
                body.active,
                json.dumps(body.filters) if body.filters else None,
                body.requires_js,
            )
        )
        cursor.execute("SELECT * FROM sources WHERE id = LAST_INSERT_ID()")
        row = cursor.fetchone()
    return _parse_source(row)


@router.patch("/{source_id}/toggle", response_model=SourceResponse)
async def toggle_source(source_id: int):
    """Toggle a source active/inactive."""
    with get_cursor() as cursor:
        cursor.execute(
            "UPDATE sources SET active = NOT active WHERE id = %s",
            (source_id,)
        )
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Source not found")
        cursor.execute("SELECT * FROM sources WHERE id = %s", (source_id,))
        row = cursor.fetchone()
    return _parse_source(row)


@router.delete("/{source_id}", status_code=204)
async def delete_source(source_id: int):
    with get_cursor() as cursor:
        cursor.execute("DELETE FROM sources WHERE id = %s", (source_id,))
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Source not found")


def _parse_source(row: dict) -> dict:
    if row.get("filters") and isinstance(row["filters"], str):
        row["filters"] = json.loads(row["filters"])
    return row
