"""
Backend Scraper Router
----------------------
Proxies scrape trigger requests from the frontend to the
internal scraper service at http://job-search-agent-scraper:9000

The scraper service is not exposed publicly — only the backend
can reach it via the shared traefik-network.
"""

import os
import httpx
from fastapi import APIRouter, HTTPException
from typing import List
from app.models import ScrapeLogResponse
from app.database import get_cursor

router = APIRouter(prefix="/scraper", tags=["scraper"])

SCRAPER_URL = os.getenv("SCRAPER_SERVICE_URL", "http://job-search-agent-scraper:9000")


async def _call_scraper(path: str) -> dict:
    """Forward a POST request to the scraper service."""
    try:
        async with httpx.AsyncClient(timeout=300.0) as client:
            response = await client.post(f"{SCRAPER_URL}{path}")
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=e.response.status_code, detail=str(e))
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Scraper service unavailable: {e}")


@router.post("/run", status_code=202)
async def run_scrape():
    """Trigger a scrape run across all active sources."""
    return await _call_scraper("/run")


@router.post("/run/{source_id}", status_code=202)
async def run_scrape_source(source_id: int):
    """Trigger a scrape run for a single source."""
    return await _call_scraper(f"/run/{source_id}")


@router.get("/logs", response_model=List[ScrapeLogResponse])
async def list_scrape_logs(limit: int = 50):
    """Return recent scrape log entries."""
    with get_cursor() as cursor:
        cursor.execute(
            "SELECT * FROM scrape_log ORDER BY started_at DESC LIMIT %s",
            (limit,)
        )
        rows = cursor.fetchall()
    return rows