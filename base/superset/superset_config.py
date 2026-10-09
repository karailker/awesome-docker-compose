# Superset configuration; everything environment specific comes from environment variables.
import os

SECRET_KEY = os.environ["SUPERSET_SECRET_KEY"]
SQLALCHEMY_DATABASE_URI = (
    f"postgresql+psycopg2://{os.environ['POSTGRES_USER']}:{os.environ['POSTGRES_PASSWORD']}"
    f"@postgres:5432/{os.environ['SUPERSET_DB']}"
)

REDIS_URL = "redis://redis:6379"
CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_URL": f"{REDIS_URL}/1",
}
DATA_CACHE_CONFIG = {**CACHE_CONFIG, "CACHE_KEY_PREFIX": "superset_data_"}

# Charts load over plain HTTP in this local setup
TALISMAN_ENABLED = False
WTF_CSRF_ENABLED = True
