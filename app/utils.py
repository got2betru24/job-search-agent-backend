import hashlib
import re
from typing import List, Optional

def hash_url(url: str) -> str:
    """SHA-256 hash of a URL for deduplication."""
    return hashlib.sha256(url.strip().encode()).hexdigest()

def title_matches_filters(title: str, filters: Optional[List[str]]) -> bool:
    """
    Check if a job title matches any filter in the list.
    Filters are case-insensitive substring matches unless
    the filter starts with ^ in which case it is treated as regex.
    Returns True if filters is None or empty (accept all).
    """
    if not filters:
        return True

    title_lower = title.lower()

    for f in filters:
        if f.startswith("^"):
            # Treat as regex
            if re.search(f, title_lower):
                return True
        else:
            # Substring match
            if f.lower() in title_lower:
                return True

    return False
