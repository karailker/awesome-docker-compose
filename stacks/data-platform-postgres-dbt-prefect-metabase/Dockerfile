# Prefect (orchestration) with dbt installed in its own virtualenv, so dbt's dependencies cannot
# clash with Prefect's.
ARG PREFECT_VERSION=3.8.8-python3.12
FROM prefecthq/prefect:${PREFECT_VERSION}
RUN python -m venv /opt/dbt \
 && /opt/dbt/bin/pip install --no-cache-dir dbt-core==1.12.5 dbt-postgres==1.10.2
ENV DBT_BIN=/opt/dbt/bin/dbt
