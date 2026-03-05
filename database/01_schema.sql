-- ============================================================
-- Job Search Agent — Database Schema
-- MySQL 8.0
--
-- Run after 00_init.sql:
--   docker exec -i mysql mysql -u root -p < sql/01_schema.sql
-- ============================================================


-- ============================================================
-- sources
-- Career pages the scraper monitors. Filters define which
-- job titles are worth promoting based on keyword/regex match.
-- ============================================================
CREATE TABLE IF NOT EXISTS sources (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    company         VARCHAR(100)    NOT NULL,
    url             VARCHAR(500)    NOT NULL UNIQUE,
    active          BOOLEAN         NOT NULL DEFAULT TRUE,

    -- JSON array of lowercase keyword strings and/or regex patterns
    -- e.g. ["engineering manager", "staff engineer", "^senior.*python"]
    -- Applied to job title during scrape. NULL means accept all titles.
    filters         JSON            DEFAULT NULL,

    -- Explicit extractor override. NULL = auto-detect from URL.
    -- Valid values: greenhouse, lever, ashby, bamboohr, workday, phenom, generic
    extractor_type  VARCHAR(50)     DEFAULT NULL,

    -- Rendering hint for the scraper service
    requires_js     BOOLEAN         NOT NULL DEFAULT FALSE,

    last_scraped_at DATETIME        DEFAULT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- jobs
-- A job can exist in a partially-populated state after pass 1
-- (title + url only) and gets enriched in pass 2 (full fields).
-- status drives the frontend feed.
-- ============================================================
CREATE TABLE IF NOT EXISTS jobs (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_id       INT UNSIGNED    NOT NULL,

    -- Pass 1 fields — populated immediately on discovery
    title           VARCHAR(255)    NOT NULL,
    job_url         VARCHAR(500)    NOT NULL UNIQUE,
    url_hash        CHAR(64)        NOT NULL UNIQUE,   -- SHA-256 of job_url

    -- Pass 2 fields — populated after full page scrape
    company         VARCHAR(100)    DEFAULT NULL,
    location        VARCHAR(500)    DEFAULT NULL,
    job_type        VARCHAR(50)     DEFAULT NULL,      -- full-time, contract, etc.
    salary          VARCHAR(100)    DEFAULT NULL,
    description     LONGTEXT        DEFAULT NULL,
    requirements    JSON            DEFAULT NULL,      -- array of requirement strings

    -- Role classification — set during pass 2, drives base resume selection
    -- engineering_manager | product_manager | engineer
    role            ENUM('engineering_manager', 'product_manager', 'engineer') DEFAULT NULL,

    -- Match score 0-100. NULL until Claude scoring is enabled.
    match_score     TINYINT UNSIGNED DEFAULT NULL,

    -- Scrape state
    -- pending   = pass 1 complete, pass 2 not yet run
    -- scraped   = pass 2 complete, fully populated
    -- failed    = pass 2 attempted but failed
    scrape_status   ENUM('pending', 'scraped', 'failed') NOT NULL DEFAULT 'pending',
    scrape_error    TEXT            DEFAULT NULL,

    -- Application status — drives frontend feed visibility
    -- archived jobs are hidden from the default feed
    status          ENUM('new', 'saved', 'applied', 'archived') NOT NULL DEFAULT 'new',

    found_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    scraped_at      DATETIME        DEFAULT NULL,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_jobs_source
        FOREIGN KEY (source_id) REFERENCES sources(id)
        ON DELETE RESTRICT
);

-- ============================================================
-- resumes
-- Base resumes are role-specific. Tailored resumes are linked
-- to a specific job via job_id.
-- ============================================================
CREATE TABLE IF NOT EXISTS resumes (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    name            VARCHAR(255)    NOT NULL,
    content         LONGTEXT        NOT NULL,

    -- Role this resume is written for
    role            ENUM('engineering_manager', 'product_manager', 'engineer') NOT NULL,

    -- is_base = TRUE for the three master resumes (one per role)
    -- is_base = FALSE for Claude-tailored versions tied to a specific job
    is_base         BOOLEAN         NOT NULL DEFAULT FALSE,

    -- NULL for base resumes, set for tailored versions
    job_id          INT UNSIGNED    DEFAULT NULL,

    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_resumes_job
        FOREIGN KEY (job_id) REFERENCES jobs(id)
        ON DELETE SET NULL,

    -- Only one base resume per role
    CONSTRAINT uq_base_resume_per_role
        UNIQUE (role, is_base),

    -- Only one tailored resume per job
    CONSTRAINT uq_tailored_resume_per_job
        UNIQUE (job_id)
);

-- ============================================================
-- scrape_log
-- One row per scrape attempt per source. Lightweight audit
-- trail — no raw HTML stored, just run metadata.
-- ============================================================
CREATE TABLE IF NOT EXISTS scrape_log (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_id       INT UNSIGNED    NOT NULL,

    started_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at     DATETIME        DEFAULT NULL,

    -- overall run outcome
    status          ENUM('running', 'success', 'failed', 'partial', 'skipped') NOT NULL DEFAULT 'running',

    jobs_found      SMALLINT UNSIGNED DEFAULT 0,   -- titles discovered on listing page
    jobs_added      SMALLINT UNSIGNED DEFAULT 0,   -- net new jobs written to DB
    jobs_filtered   SMALLINT UNSIGNED DEFAULT 0,   -- rejected by title filters
    jobs_skipped    SMALLINT UNSIGNED DEFAULT 0,   -- already existed in DB

    error_message   TEXT            DEFAULT NULL,

    CONSTRAINT fk_scrape_log_source
        FOREIGN KEY (source_id) REFERENCES sources(id)
        ON DELETE CASCADE
);

-- ============================================================
-- Indexes
-- ============================================================

-- Fast feed queries by status
CREATE INDEX idx_jobs_status          ON jobs(status);

-- Fast lookups for deduplication during scrape
CREATE INDEX idx_jobs_url_hash        ON jobs(url_hash);

-- Filter jobs by source
CREATE INDEX idx_jobs_source          ON jobs(source_id);

-- Scrape log queries by source and time
CREATE INDEX idx_scrape_log_source    ON scrape_log(source_id);
CREATE INDEX idx_scrape_log_started   ON scrape_log(started_at);

-- Tailored resume lookup by job
CREATE INDEX idx_resumes_job          ON resumes(job_id);