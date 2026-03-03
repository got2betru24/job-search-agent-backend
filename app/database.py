import os
import mysql.connector
from mysql.connector.pooling import MySQLConnectionPool
from contextlib import contextmanager

# ── Connection pool ──────────────────────────────────────────
_pool = MySQLConnectionPool(
    pool_name="job_search_pool",
    pool_size=5,
    host=os.getenv("DB_HOST", "mysql"),
    port=int(os.getenv("DB_PORT", 3306)),
    database=os.getenv("DB_NAME", "job_search"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD"),
)

@contextmanager
def get_connection():
    """Yield a connection from the pool, auto-commit and return on exit."""
    conn = _pool.get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

@contextmanager
def get_cursor(dictionary: bool = True):
    """Yield a cursor, handling connection lifecycle."""
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=dictionary)
        try:
            yield cursor
        finally:
            cursor.close()
