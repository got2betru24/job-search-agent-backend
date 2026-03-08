from pydantic import BaseModel
from typing import Optional, List
from enum import Enum
from datetime import datetime

# ── Enums ────────────────────────────────────────────────────

class JobStatus(str, Enum):
    new         = "new"
    saved       = "saved"
    applied     = "applied"
    archived    = "archived"

class JobRole(str, Enum):
    engineering_manager = "engineering_manager"
    product_manager     = "product_manager"
    engineer            = "engineer"

class ScrapeStatus(str, Enum):
    pending = "pending"
    scraped = "scraped"
    failed  = "failed"

# ── Job models ───────────────────────────────────────────────

class JobBase(BaseModel):
    title:          str
    job_url:        str
    company:        Optional[str]           = None
    location:       Optional[str]           = None
    job_type:       Optional[str]           = None
    salary:         Optional[str]           = None
    description:    Optional[str]           = None
    requirements:   Optional[List[str]]     = None
    role:           Optional[JobRole]       = None
    match_score:    Optional[int]           = None

class JobResponse(JobBase):
    id:             int
    source_id:      int
    status:         JobStatus
    scrape_status:  ScrapeStatus
    found_at:       datetime
    scraped_at:     Optional[datetime]      = None
    updated_at:     datetime

    class Config:
        from_attributes = True

class JobStatusUpdate(BaseModel):
    status: JobStatus

# ── Source models ─────────────────────────────────────────────

class SourceBase(BaseModel):
    company:        str
    url:            str
    active:         bool                    = True
    extractor_type: Optional[str]           = None
    filters:        Optional[List[str]]     = None
    requires_js:    bool                    = False

class SourceResponse(SourceBase):
    id:              int
    last_scraped_at: Optional[datetime]     = None
    created_at:      datetime

    class Config:
        from_attributes = True

class SourceCreate(SourceBase):
    pass

# ── Resume models ─────────────────────────────────────────────

class ResumeBase(BaseModel):
    name:       str
    content:    str
    role:       JobRole
    is_base:    bool                        = False
    job_id:     Optional[int]              = None

class ResumeResponse(ResumeBase):
    id:         int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ResumeUpdate(BaseModel):
    name:       Optional[str]   = None
    content:    Optional[str]   = None

# ── Scrape log models ─────────────────────────────────────────

class ScrapeLogResponse(BaseModel):
    id:             int
    source_id:      int
    started_at:     datetime
    finished_at:    Optional[datetime]  = None
    status:         str
    jobs_found:     int
    jobs_added:     int
    jobs_filtered:  int
    jobs_skipped:   int
    error_message:  Optional[str]       = None

    class Config:
        from_attributes = True