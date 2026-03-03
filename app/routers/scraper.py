from fastapi import APIRouter, HTTPException
from typing import List
from app.models import ScrapeLogResponse
from app.database import get_cursor
from app.scraper import fetch_page, extract_job_links, scrape_job_detail
from app.utils import hash_url, title_matches_filters
import json
import logging

router = APIRouter(prefix="/scraper", tags=["scraper"])
logger = logging.getLogger(__name__)


@router.post("/run", status_code=202)
async def run_scrape():
    """
    Trigger a scrape run across all active sources.
    Returns a summary of results per source.
    """
    with get_cursor() as cursor:
        cursor.execute("SELECT * FROM sources WHERE active = TRUE")
        sources = cursor.fetchall()

    if not sources:
        raise HTTPException(status_code=404, detail="No active sources found")

    results = []
    for source in sources:
        result = await _scrape_source(source)
        results.append(result)

    return {"sources_scraped": len(results), "results": results}


@router.post("/run/{source_id}", status_code=202)
async def run_scrape_source(source_id: int):
    """Trigger a scrape run for a single source."""
    with get_cursor() as cursor:
        cursor.execute("SELECT * FROM sources WHERE id = %s", (source_id,))
        source = cursor.fetchone()

    if not source:
        raise HTTPException(status_code=404, detail="Source not found")

    result = await _scrape_source(source)
    return result


@router.get("/logs", response_model=List[ScrapeLogResponse])
async def list_scrape_logs(limit: int = 50):
    with get_cursor() as cursor:
        cursor.execute(
            "SELECT * FROM scrape_log ORDER BY started_at DESC LIMIT %s",
            (limit,)
        )
        rows = cursor.fetchall()
    return rows


async def _scrape_source(source: dict) -> dict:
    """
    Core scrape logic for a single source.
    Pass 1: fetch listing page, extract (title, url) pairs, apply filters.
    Pass 2: for new URLs, scrape job detail page and write to DB.
    """
    filters = source.get("filters")
    if filters and isinstance(filters, str):
        filters = json.loads(filters)

    # ── Start scrape log entry ───────────────────────────────
    with get_cursor() as cursor:
        cursor.execute(
            "INSERT INTO scrape_log (source_id, status) VALUES (%s, 'running')",
            (source["id"],)
        )
        cursor.execute("SELECT LAST_INSERT_ID() as log_id")
        log_id = cursor.fetchone()["log_id"]

    jobs_found = jobs_added = jobs_filtered = jobs_skipped = 0
    error_message = None

    try:
        # ── Pass 1: fetch listing page ───────────────────────
        html = await fetch_page(source["url"])
        if not html:
            raise Exception(f"Failed to fetch listing page: {source['url']}")

        job_links = extract_job_links(html, source["url"])
        jobs_found = len(job_links)

        for title, job_url in job_links:

            # Apply title filters
            if not title_matches_filters(title, filters):
                jobs_filtered += 1
                continue

            url_hash = hash_url(job_url)

            # Check if URL already exists in DB
            with get_cursor() as cursor:
                cursor.execute(
                    "SELECT id FROM jobs WHERE url_hash = %s", (url_hash,)
                )
                existing = cursor.fetchone()

            if existing:
                jobs_skipped += 1
                continue

            # ── Pass 2: scrape job detail ────────────────────
            detail = await scrape_job_detail(job_url)

            with get_cursor() as cursor:
                cursor.execute(
                    """INSERT INTO jobs
                       (source_id, title, job_url, url_hash, company,
                        location, job_type, salary, description, requirements,
                        scrape_status, scraped_at)
                       VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())""",
                    (
                        source["id"],
                        title,
                        job_url,
                        url_hash,
                        detail.get("company") or source["company"],
                        detail.get("location"),
                        detail.get("job_type"),
                        detail.get("salary"),
                        detail.get("description"),
                        json.dumps(detail["requirements"]) if detail.get("requirements") else None,
                        "scraped" if detail.get("description") else "pending",
                    )
                )
            jobs_added += 1

        # ── Update source last_scraped_at ────────────────────
        with get_cursor() as cursor:
            cursor.execute(
                "UPDATE sources SET last_scraped_at = NOW() WHERE id = %s",
                (source["id"],)
            )

        log_status = "success"

    except Exception as e:
        logger.error(f"Scrape failed for {source['company']}: {e}")
        error_message = str(e)
        log_status = "failed"

    # ── Finalise scrape log ──────────────────────────────────
    with get_cursor() as cursor:
        cursor.execute(
            """UPDATE scrape_log SET
               status = %s, finished_at = NOW(),
               jobs_found = %s, jobs_added = %s,
               jobs_filtered = %s, jobs_skipped = %s,
               error_message = %s
               WHERE id = %s""",
            (log_status, jobs_found, jobs_added,
             jobs_filtered, jobs_skipped, error_message, log_id)
        )

    return {
        "source_id":    source["id"],
        "company":      source["company"],
        "status":       log_status,
        "jobs_found":   jobs_found,
        "jobs_added":   jobs_added,
        "jobs_filtered": jobs_filtered,
        "jobs_skipped": jobs_skipped,
        "error":        error_message,
    }
