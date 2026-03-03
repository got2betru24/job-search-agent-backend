#!/bin/bash
# =============================================================
# Job Search Agent — Database Initialization Script
#
# Run once from the backend project root when setting up:
#   chmod +x scripts/db_init.sh
#   ./scripts/db_init.sh
#
# Expected project structure:
#   backend/
#   ├── .env                  ← DB_ROOT_PASSWORD, DB_NAME, DB_USER, DB_PASSWORD
#   ├── database/
#   │   ├── 01_schema.sql
#   │   └── 02_seed.sql
#   └── scripts/
#       └── db_init.sh        ← this file (run from backend/)
# =============================================================

set -e  # exit on any error

# Resolve project root relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env from project root
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "Error: .env file not found at $PROJECT_ROOT/.env"
    echo "Run this script from the backend project root."
    exit 1
fi

set -a
source "$PROJECT_ROOT/.env"
set +a

# Validate required variables
for var in DB_ROOT_PASSWORD DB_NAME DB_USER DB_PASSWORD; do
    if [ -z "${!var}" ]; then
        echo "Error: $var is not set in .env"
        exit 1
    fi
done

echo "=> Creating database and user..."
docker exec -i mysql mysql -u root -p${DB_ROOT_PASSWORD} << SQLEOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQLEOF

echo "=> Running schema..."
docker exec -i mysql mysql -u root -p${DB_ROOT_PASSWORD} ${DB_NAME} < "$PROJECT_ROOT/database/01_schema.sql"

echo "=> Running seed..."
docker exec -i mysql mysql -u root -p${DB_ROOT_PASSWORD} ${DB_NAME} < "$PROJECT_ROOT/database/02_seed.sql"

echo ""
echo "Done. Database '${DB_NAME}' is ready."