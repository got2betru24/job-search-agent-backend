###################################################
# Stage: backend-base
###################################################
FROM python:3.13-slim AS backend-base
WORKDIR /app/backend

# Install system dependencies useful for scraping
# (httpx needs these for certain SSL operations)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

###################################################
# Stage: backend-dev
###################################################
FROM backend-base AS backend-dev
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 8000
# app.main:app because main.py lives in backend/app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

###################################################
# Stage: backend-prod
###################################################
FROM backend-base AS backend-prod
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]