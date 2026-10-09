#!/usr/bin/env bash
# Functional test: run the setup wizard through the API (admin user + the sample "analytics"
# database), then run a native SQL query against that database.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck disable=SC1091
[ -f .env ] && { set -a; . ./.env; set +a; }
BASE=http://localhost:${METABASE_PORT:-3000}
JSON='Content-Type: application/json'
fail() { echo "::error::metabase smoke test: $*"; exit 1; }
py() { python3 -c "$@"; }

deadline=$((SECONDS + 300))
until curl -fsS "$BASE/api/health" 2>/dev/null | grep -q ok; do
  [ $SECONDS -ge $deadline ] && fail "Metabase did not become healthy"
  sleep 5
done
echo "ok: Metabase is healthy"

setup_token=$(curl -fsS -m 60 "$BASE/api/session/properties" | py 'import json,sys; print(json.load(sys.stdin)["setup-token"])') || fail "no setup token (already set up?)"
email=${METABASE_ADMIN_EMAIL:-admin@example.com}; password=${METABASE_ADMIN_PASSWORD:-Admin-password-123}
body=$(py '
import json, sys
tok, email, pw = sys.argv[1:4]
print(json.dumps({
  "token": tok,
  "user": {"first_name": "Smoke", "last_name": "Test", "email": email, "password": pw, "site_name": "smoke"},
  "prefs": {"site_name": "smoke", "allow_tracking": False},
}))' "$setup_token" "$email" "$password")
curl -fsS -m 120 -H "$JSON" -d "$body" "$BASE/api/setup" >/dev/null || fail "setup wizard API failed"
echo "ok: setup completed (admin user created)"

session=$(curl -fsS -m 60 -H "$JSON" -d "{\"username\":\"$email\",\"password\":\"$password\"}" "$BASE/api/session" | py 'import json,sys; print(json.load(sys.stdin)["id"])') || fail "login failed"
db_body=$(py '
import json, sys
user, pw = sys.argv[1:3]
print(json.dumps({"engine": "postgres", "name": "analytics",
                  "details": {"host": "postgres", "port": 5432, "dbname": "analytics", "user": user, "password": pw, "ssl": False}}))' \
  "${POSTGRES_USER:-metabase}" "${POSTGRES_PASSWORD:-metabase}")
db_id=$(curl -fsS -m 120 -H "X-Metabase-Session: $session" -H "$JSON" -d "$db_body" "$BASE/api/database" | py 'import json,sys; print(json.load(sys.stdin)["id"])') || fail "cannot add the analytics database"
echo "ok: analytics database added (id $db_id)"
total=$(curl -fsS -m 120 -H "X-Metabase-Session: $session" -H "$JSON" \
  -d "{\"database\":$db_id,\"type\":\"native\",\"native\":{\"query\":\"SELECT sum(amount) AS total FROM orders\"}}" "$BASE/api/dataset" \
  | py 'import json,sys; print(json.load(sys.stdin)["data"]["rows"][0][0])') || fail "native query failed"
[ "${total%.0}" = 1260.5 ] || [ "$total" = 1260.5 ] || fail "unexpected total: $total"
echo "ok: native query returns $total"
echo "Metabase functional smoke test passed"
