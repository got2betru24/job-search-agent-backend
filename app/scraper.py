import httpx
from bs4 import BeautifulSoup
from typing import List, Tuple, Optional
import logging

logger = logging.getLogger(__name__)

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}

async def fetch_page(url: str) -> Optional[str]:
    """
    Fetch a page and return the HTML as a string.
    Returns None on failure.
    """
    try:
        async with httpx.AsyncClient(headers=HEADERS, timeout=15.0, follow_redirects=True) as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.text
    except httpx.HTTPError as e:
        logger.error(f"HTTP error fetching {url}: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error fetching {url}: {e}")
        return None

def extract_job_links(html: str, base_url: str) -> List[Tuple[str, str]]:
    """
    Extract (title, url) pairs from a career listing page.
    Returns a list of tuples.

    This is a best-effort generic extractor. Career pages vary
    wildly in structure — this covers common patterns but some
    sources may need custom extraction logic added here.
    """
    soup = BeautifulSoup(html, "html.parser")
    results = []

    # Common patterns for job listing links:
    # 1. <a> tags whose href contains common job path patterns
    # 2. <a> tags inside elements with job-related class names
    job_path_patterns = [
        "/job/", "/jobs/", "/careers/", "/position/",
        "/opening/", "/role/", "/posting/"
    ]

    seen_urls = set()

    for a_tag in soup.find_all("a", href=True):
        href = a_tag["href"].strip()
        title = a_tag.get_text(strip=True)

        if not title or len(title) < 4:
            continue

        # Resolve relative URLs
        if href.startswith("/"):
            from urllib.parse import urlparse
            parsed = urlparse(base_url)
            href = f"{parsed.scheme}://{parsed.netloc}{href}"
        elif not href.startswith("http"):
            continue

        # Check if the URL looks like a job posting
        if not any(pattern in href.lower() for pattern in job_path_patterns):
            continue

        if href in seen_urls:
            continue

        seen_urls.add(href)
        results.append((title, href))

    return results

async def scrape_job_detail(url: str) -> dict:
    """
    Scrape a full job detail page and extract structured fields.
    Returns a dict with description, requirements, location,
    salary, and job_type where detectable.

    Claude will eventually handle this parsing — for now this
    is a basic best-effort text extraction.
    """
    html = await fetch_page(url)
    if not html:
        return {}

    soup = BeautifulSoup(html, "html.parser")

    # Remove nav, footer, header noise
    for tag in soup(["nav", "footer", "header", "script", "style"]):
        tag.decompose()

    # Get main content text
    main = soup.find("main") or soup.find("article") or soup.body
    text = main.get_text(separator="\n", strip=True) if main else ""

    return {
        "description": text[:5000] if text else None,  # cap at 5k chars for now
        "requirements": None,   # TODO: Claude parsing
        "location": None,       # TODO: Claude parsing
        "salary": None,         # TODO: Claude parsing
        "job_type": None,       # TODO: Claude parsing
    }
