# The official image ships without a PostgreSQL driver; add it to Superset's virtualenv.
ARG SUPERSET_VERSION=6.1.0
FROM apache/superset:${SUPERSET_VERSION}
USER root
RUN uv pip install --python /app/.venv/bin/python --no-cache psycopg2-binary==2.9.10
USER superset
