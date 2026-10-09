#!/bin/sh
# Runs once, when the Postgres volume is empty: one server, three databases.
#   warehouse (POSTGRES_DB)  - dbt builds the analytics tables here
#   metabase                 - Metabase application database
#   prefect                  - Prefect server database
set -eu
for db in metabase prefect; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE $db OWNER \"$POSTGRES_USER\""
done
