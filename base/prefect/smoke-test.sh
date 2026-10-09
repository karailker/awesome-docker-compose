#!/usr/bin/env bash
# Functional test: the API is healthy, runs on PostgreSQL, and the worker has registered the
# "default" work pool and is online.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="prefect smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
API=http://localhost:4200/api

retry 120 "API is healthy" curl -fsS "$API/health"
pool_has_worker() {
  curl -fsS -m 30 -H "$JSON" -d '{}' "$API/work_pools/default/workers/filter" \
    | py 'import json,sys; w=json.load(sys.stdin); sys.exit(0 if any(x["status"]=="ONLINE" for x in w) else 1)'
}
retry 120 "worker is online in work pool 'default'" pool_has_worker
# the connection URL is masked by the settings API, so look at the database itself
load_env
rev=$(docker compose exec -T prefect_postgres psql -U "${POSTGRES_USER:-myuser}" -d "${POSTGRES_DB:-mydatabase}" -tAc "select version_num from alembic_version" 2>/dev/null | tr -d '[:space:]')
[ -n "$rev" ] || fail "the Prefect schema is not in PostgreSQL (alembic_version is empty)"
step "server uses PostgreSQL (schema revision $rev)"
echo "Prefect functional smoke test passed"
