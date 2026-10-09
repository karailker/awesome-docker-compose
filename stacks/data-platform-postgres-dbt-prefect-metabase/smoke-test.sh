#!/usr/bin/env bash
# Functional test of the whole path: run the Prefect deployment -> dbt seeds/models/tests ->
# analytics tables in Postgres -> Metabase queries them.
# Run by scripts/smoke.sh after the stack is up (working directory: this directory).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck disable=SC1091
[ -f .env ] && { set -a; . ./.env; set +a; }
PREFECT=http://localhost:${PREFECT_PORT:-4200}/api
MB=http://localhost:${METABASE_PORT:-3000}
JSON='Content-Type: application/json'
fail() { echo "::error::data platform smoke test: $*"; exit 1; }
py() { python3 -c "$@"; }

retry() {
  local secs=$1 what=$2; shift 2
  local deadline=$((SECONDS + secs))
  until "$@" >/dev/null 2>&1; do
    [ $SECONDS -ge $deadline ] && fail "$what (timeout after ${secs}s)"
    sleep 5
  done
  echo "ok: $what"
}

# 1. Prefect: the deployment exists and a run completes
retry 180 "Prefect API is healthy" curl -fsS "$PREFECT/health"
find_deployment() {
  curl -fsS -m 30 -H "$JSON" -d '{"deployments":{"name":{"any_":["dbt-hourly"]}}}' "$PREFECT/deployments/filter" \
    | py 'import json,sys; print(json.load(sys.stdin)[0]["id"])'
}
retry 180 "deployment dbt-hourly is registered" find_deployment
dep=$(find_deployment)
run=$(curl -fsS -m 30 -H "$JSON" -d '{}' "$PREFECT/deployments/$dep/create_flow_run" | py 'import json,sys; print(json.load(sys.stdin)["id"])') || fail "cannot start a flow run"
echo "flow run $run started"
deadline=$((SECONDS + 600))
while :; do
  state=$(curl -fsS -m 30 "$PREFECT/flow_runs/$run" | py 'import json,sys; print(json.load(sys.stdin)["state"]["type"])')
  case $state in
    COMPLETED) break ;;
    FAILED|CRASHED|CANCELLED) fail "flow run ended as $state (see 'docker compose logs pipeline')" ;;
  esac
  [ $SECONDS -ge $deadline ] && fail "flow run still $state after 600s"
  sleep 5
done
echo "ok: flow run completed (dbt seed, run and test)"

# 2. the mart table is in the warehouse
us=$(docker compose exec -T postgres psql -U "${POSTGRES_USER:-platform}" -d "${POSTGRES_DB:-warehouse}" -tAc \
  "select revenue from analytics.revenue_by_country where country = 'US'") || fail "cannot query the warehouse"
[ "${us//[[:space:]]/}" = 720.00 ] || fail "unexpected US revenue: $us"
echo "ok: analytics.revenue_by_country is built (US revenue $us)"

# 3. Metabase can query it
retry 300 "Metabase is healthy" bash -c "curl -fsS $MB/api/health | grep -q ok"
setup_token=$(curl -fsS -m 60 "$MB/api/session/properties" | py 'import json,sys; print(json.load(sys.stdin)["setup-token"])') || fail "no Metabase setup token"
email=${METABASE_ADMIN_EMAIL:-admin@example.com}; password=${METABASE_ADMIN_PASSWORD:-Admin-password-123}
body=$(py '
import json, sys
tok, email, pw = sys.argv[1:4]
print(json.dumps({"token": tok,
  "user": {"first_name": "Smoke", "last_name": "Test", "email": email, "password": pw, "site_name": "smoke"},
  "prefs": {"site_name": "smoke", "allow_tracking": False}}))' "$setup_token" "$email" "$password")
curl -fsS -m 120 -H "$JSON" -d "$body" "$MB/api/setup" >/dev/null || fail "Metabase setup failed"
session=$(curl -fsS -m 60 -H "$JSON" -d "{\"username\":\"$email\",\"password\":\"$password\"}" "$MB/api/session" | py 'import json,sys; print(json.load(sys.stdin)["id"])') || fail "Metabase login failed"
db_body=$(py '
import json, sys
user, pw, db = sys.argv[1:4]
print(json.dumps({"engine": "postgres", "name": "warehouse",
  "details": {"host": "postgres", "port": 5432, "dbname": db, "user": user, "password": pw, "ssl": False}}))' \
  "${POSTGRES_USER:-platform}" "${POSTGRES_PASSWORD:-platform}" "${POSTGRES_DB:-warehouse}")
db_id=$(curl -fsS -m 120 -H "X-Metabase-Session: $session" -H "$JSON" -d "$db_body" "$MB/api/database" | py 'import json,sys; print(json.load(sys.stdin)["id"])') || fail "cannot add the warehouse to Metabase"
total=$(curl -fsS -m 120 -H "X-Metabase-Session: $session" -H "$JSON" \
  -d "{\"database\":$db_id,\"type\":\"native\",\"native\":{\"query\":\"SELECT sum(revenue) FROM analytics.revenue_by_country\"}}" "$MB/api/dataset" \
  | py 'import json,sys; print(json.load(sys.stdin)["data"]["rows"][0][0])') || fail "Metabase query failed"
[ "$total" = 1260.5 ] || [ "$total" = 1260.50 ] || fail "unexpected total revenue in Metabase: $total"
echo "ok: Metabase reads the dbt mart (total revenue $total)"
echo "Data platform functional smoke test passed"
