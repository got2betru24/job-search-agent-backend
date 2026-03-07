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
from fastapi import APIRouter, HTTPException, BackgroundTasks, Query
from typing import List, Optional
from app.models import ScrapeLogResponse
from app.database import get_cursor

router = APIRouter(prefix="/scraper", tags=["scraper"])

SCRAPER_URL = os.getenv("SCRAPER_SERVICE_URL", "http://job-search-agent-scraper:9000")


async def _call_scraper(path: str) -> dict:
    """Forward a POST request to the scraper service."""
    import logging

    logger = logging.getLogger(__name__)
    try:
        async with httpx.AsyncClient(timeout=300.0) as client:
            response = await client.post(f"{SCRAPER_URL}{path}")
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as e:
        logger.error(f"Scraper returned error {e.response.status_code} for {path}: {e}")
    except httpx.RequestError as e:
        logger.error(f"Scraper service unavailable for {path}: {e}")


@router.post("/run", status_code=202)
async def run_scrape(background_tasks: BackgroundTasks):
    """Trigger a scrape run across all active sources."""
    background_tasks.add_task(_call_scraper, "/run")
    return {"status": "started"}


@router.post("/run/{source_id}", status_code=202)
async def run_scrape_source(source_id: int):
    """Trigger a scrape run for a single source."""
    return await _call_scraper(f"/run/{source_id}")


@router.get("/logs", response_model=List[ScrapeLogResponse])
async def list_scrape_logs(limit: int = 50):
    """Return recent scrape log entries."""
    with get_cursor() as cursor:
        cursor.execute("SELECT * FROM scrape_log ORDER BY started_at DESC LIMIT %s", (limit,))
        rows = cursor.fetchall()
    return rows


@router.get("/logs/raw")
async def get_raw_logs(
    source: Optional[str] = Query(None),
    level: Optional[str] = Query(None),
    filter_type: Optional[str] = Query(None),
    limit: int = Query(2000),
):
    """Proxy raw log lines from the scraper service."""
    import logging

    logger = logging.getLogger(__name__)
    params = {}
    if source:
        params["source"] = source
    if level:
        params["level"] = level
    if filter_type:
        params["filter_type"] = filter_type
    if limit:
        params["limit"] = limit

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(f"{SCRAPER_URL}/logs/raw", params=params)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as e:
        logger.error(f"Scraper log fetch error {e.response.status_code}: {e}")
        raise HTTPException(status_code=502, detail="Scraper service returned an error")
    except httpx.RequestError as e:
        logger.error(f"Scraper service unavailable: {e}")
        raise HTTPException(status_code=503, detail="Scraper service unavailable")
