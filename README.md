# Job Search Agent — Backend

A FastAPI backend for a personal AI-powered job search agent. Scrapes curated company career pages, stores structured job data in MySQL, and exposes a REST API consumed by the frontend. Claude integration for resume tailoring and match scoring is stubbed and ready for the next phase.

> **This is the backend repo.** The frontend (React/TypeScript/Vite) lives in a separate repository: [**job-search-agent-frontend**](https://github.com/got2betru24/job-search-agent-frontend)

---

## What It Does

- **Career page scraping** — monitors up to 20 curated company career pages on demand, extracting job listings via a two-pass approach (title filter → full detail scrape)
- **Title filtering** — keyword and regex filters applied at scrape time so only relevant roles (EM, PM, Senior/Staff/Principal IC) make it into the database
- **Deduplication** — SHA-256 URL hashing ensures jobs are never double-counted, and archived jobs never resurface as new
- **REST API** — serves jobs, resumes, sources, and scrape logs to the frontend
- **Claude-ready** — `agent.py` and `tools.py` are stubbed for resume tailoring and match scoring in the next phase

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | FastAPI 0.132+ |
| Language | Python 3.13 |
| Database | MySQL 8.0 (shared container) |
| DB driver | mysql-connector-python |
| HTTP client | httpx (async) |
| HTML parsing | BeautifulSoup4 |
| AI | Anthropic Claude (stubbed) |
| Reverse proxy | Traefik v3.6 (external) |
| Container | Docker + Compose v2 |

---

## Project Structure

```
backend/
├── .devcontainer/
│   └── devcontainer.json       # VS Code Dev Container config
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app, middleware, router registration
│   ├── database.py             # MySQL connection pool and cursor context managers
│   ├── models.py               # Pydantic request/response models and enums
│   ├── scraper.py              # httpx page fetching and BeautifulSoup extraction
│   ├── utils.py                # URL hashing, title filter matching
│   ├── agent.py                # Claude agent loop (stub)
│   ├── tools.py                # Claude tool definitions (stub)
│   └── routers/
│       ├── __init__.py
│       ├── jobs.py             # GET /jobs, PATCH /jobs/:id/status
│       ├── resumes.py          # GET /resumes, PATCH /resumes/:id
│       ├── sources.py          # GET/POST /sources, PATCH /sources/:id/toggle
│       └── scraper.py          # POST /scraper/run, GET /scraper/logs
├── database/
│   ├── 01_schema.sql           # Tables, constraints, indexes
│   └── 02_seed.sql             # Sources (20 placeholders) + base resume stubs
├── scripts/
│   └── db_init.sh              # One-time DB setup script (run manually)
├── .env                        # Local secrets — never commit this
├── Dockerfile                  # backend-base, backend-dev, backend-prod stages
└── compose.yml                 # Backend service + external traefik-network
```

---

## API Endpoints

All endpoints are served under the `/api` prefix via Traefik.
Swagger UI is available at `http://job-search-agent.local/api/docs`.

### Jobs
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/jobs` | List jobs (excludes archived by default) |
| `GET` | `/api/jobs?status=archived` | List archived jobs |
| `GET` | `/api/jobs?role=engineering_manager` | Filter by role |
| `GET` | `/api/jobs/{id}` | Get a single job |
| `PATCH` | `/api/jobs/{id}/status` | Update job status |

### Resumes
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/resumes` | List all resumes (base + tailored) |
| `GET` | `/api/resumes/{id}` | Get a single resume |
| `PATCH` | `/api/resumes/{id}` | Update resume name or content |
| `GET` | `/api/resumes/job/{job_id}` | Get tailored resume for a job |

### Sources
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/sources` | List all career page sources |
| `POST` | `/api/sources` | Add a new source |
| `PATCH` | `/api/sources/{id}/toggle` | Toggle source active/inactive |
| `DELETE` | `/api/sources/{id}` | Remove a source |

### Scraper
| Method | Path | Description |
|---|---|---|
| `POST` | `/api/scraper/run` | Scrape all active sources |
| `POST` | `/api/scraper/run/{source_id}` | Scrape a single source |
| `GET` | `/api/scraper/logs` | Recent scrape run history |

### Health
| Method | Path | Description |
|---|---|---|
| `GET` | `/api/health` | Health check |

---

## Job Status Flow

```
new → saved → applied
  ↘    ↓
    archived
```

Archived jobs are excluded from the default `GET /api/jobs` feed but preserved in the database. The scraper recognizes their URL hash and will never re-insert them as new.

---

## Scraper: Two-Pass Design

**Pass 1 — lightweight listing scrape**
- Fetch the career page listing URL
- Extract `(title, url)` pairs from anchor tags
- Apply title filters — only titles matching a keyword or regex are promoted
- Check URL hash against the database — skip if already seen

**Pass 2 — full job detail scrape**
- For each new URL, fetch the full job detail page
- Extract description and available structured fields
- Write to the `jobs` table with `scrape_status = scraped`
- Log results to `scrape_log`

Claude parsing of description → structured fields (requirements, location, salary, role classification) is the next phase.

---

## Getting Started

### Prerequisites

- Docker Engine 20.10.21+
- Docker Compose v2.13.0+
- The shared MySQL container running on `traefik-network`
- The shared Traefik container running on `traefik-network`

### 1. Add hostname to /etc/hosts

```bash
echo "127.0.0.1  job-search-agent.local" | sudo tee -a /etc/hosts
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env with your actual values
```

Required variables:

| Variable | Description |
|---|---|
| `DB_HOST` | MySQL container name (default: `mysql`) |
| `DB_PORT` | MySQL port (default: `3306`) |
| `DB_NAME` | Database name (e.g. `job_search`) |
| `DB_USER` | Database user |
| `DB_PASSWORD` | Database password |
| `ANTHROPIC_API_KEY` | Your Anthropic API key |
| `CORS_ORIGINS` | Allowed origins (default: `http://localhost`) |

### 3. Initialize the database

Run once to create the database, user, tables, and seed data:

```bash
chmod +x scripts/db_init.sh
./scripts/db_init.sh
```

### 4. Start the backend

```bash
docker compose up --build
```

The API will be available at `http://job-search-agent.local/api`.  
Swagger docs at `http://job-search-agent.local/api/docs`.

---

## Development Notes

- **Hot reload** is enabled in `backend-dev` — `app/` is mounted as a volume so code changes are reflected immediately without rebuilding
- **VS Code Dev Container** — open the `backend/` folder in VS Code and select "Reopen in Container" to get a fully configured Python environment with Ruff, Pylance, and correct import paths
- The **Playwright scraper service** is a planned separate container for career pages that require JavaScript rendering. Sources with `requires_js = TRUE` in the database are currently skipped by the httpx scraper
- `agent.py` and `tools.py` are intentional stubs — Claude integration comes after the scraper is validated end-to-end

---

## Database

Schema and seed files live in `database/`. The init script handles everything — see **Getting Started** above.

| Table | Purpose |
|---|---|
| `sources` | Career page URLs with filter config |
| `jobs` | Scraped job postings, structured fields, status |
| `resumes` | Base resumes per role + Claude-tailored versions |
| `scrape_log` | Lightweight audit trail per scrape run |

---

## Roadmap

- [ ] Wire frontend to real API (replace fake data)
- [ ] Claude parsing: description → structured fields (requirements, location, salary, role)
- [ ] Claude match scoring: base resume vs job description
- [ ] Claude resume tailoring: `POST /api/jobs/{id}/tailor`
- [ ] Scheduled scraping (APScheduler or cron)
- [ ] Playwright scraper service for JS-rendered career pages
- [ ] Cover letter generation
- [ ] Source manager UI