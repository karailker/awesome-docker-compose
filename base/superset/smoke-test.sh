#!/usr/bin/env bash
# Functional test: sign in through the API, register the sample "analytics" database and run a
# SQL query against it, the way SQL Lab / charts do.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck disable=SC1091
[ -f .env ] && { set -a; . ./.env; set +a; }
BASE=http://localhost:${SUPERSET_PORT:-8088}
JSON='Content-Type: application/json'
fail() { echo "::error::superset smoke test: $*"; exit 1; }
py() { python3 -c "$@"; }
jar=$(mktemp)

deadline=$((SECONDS + 300))
until curl -fsS "$BASE/health" >/dev/null 2>&1; do
  [ $SECONDS -ge $deadline ] && fail "Superset did not become healthy"
  sleep 5
done
echo "ok: Superset is healthy"

token=$(curl -fsS -m 60 "$BASE/api/v1/security/login" -H "$JSON" \
  -d "{\"username\":\"${SUPERSET_ADMIN_USER:-admin}\",\"password\":\"${SUPERSET_ADMIN_PASSWORD:-admin}\",\"provider\":\"db\",\"refresh\":true}" \
  | py 'import json,sys; print(json.load(sys.stdin)["access_token"])') || fail "login failed"
auth="Authorization: Bearer $token"
echo "ok: admin login works"

csrf=$(curl -fsS -m 60 -c "$jar" -H "$auth" "$BASE/api/v1/security/csrf_token/" | py 'import json,sys; print(json.load(sys.stdin)["result"])') || fail "no CSRF token"
post() { curl -fsS -m 120 -b "$jar" -H "$auth" -H "X-CSRFToken: $csrf" -H "Referer: $BASE/" -H "$JSON" -d "$2" "$BASE/api/v1/$1"; }

uri="postgresql+psycopg2://${POSTGRES_USER:-superset}:${POSTGRES_PASSWORD:-superset}@postgres:5432/analytics"
db_id=$(post database/ "{\"database_name\":\"analytics\",\"sqlalchemy_uri\":\"$uri\",\"expose_in_sqllab\":true}" \
  | py 'import json,sys; print(json.load(sys.stdin)["id"])') || fail "cannot register the analytics database"
echo "ok: database registered (id $db_id)"

total=$(post sqllab/execute/ "{\"database_id\":$db_id,\"sql\":\"SELECT sum(amount) AS total FROM orders\",\"runAsync\":false,\"queryLimit\":10}" \
  | py 'import json,sys; print(json.load(sys.stdin)["data"][0]["total"])') || fail "SQL Lab query failed"
[ "$total" = "1260.5" ] || [ "$total" = "1260.50" ] || fail "unexpected total: $total"
echo "ok: SQL Lab query returns $total"
rm -f "$jar"
echo "Superset functional smoke test passed"
