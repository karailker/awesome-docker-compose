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
db=$(curl -fsS -m 30 "$API/admin/settings" | py 'import json,sys; print(json.load(sys.stdin)["server"]["database"]["connection_url"])') || fail "cannot read settings"
case $db in *postgresql*) step "server uses PostgreSQL" ;; *) fail "server does not use PostgreSQL ($db)" ;; esac
echo "Prefect functional smoke test passed"
