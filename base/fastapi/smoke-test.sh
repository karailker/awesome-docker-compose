#!/usr/bin/env bash
# Functional test of the example API: health, root, path parameter, validation errors and the POST /echo endpoint.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="fastapi smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
A=http://localhost:${FASTAPI_PORT:-8000}

retry 120 "API is healthy" curl -fsS "$A/health"
[ "$(curl -fsS "$A/" | py 'import json,sys; print(json.load(sys.stdin)["message"])')" = "Hello from FastAPI!" ] || fail "GET / returned another message"
item=$(curl -fsS "$A/items/7" | py 'import json,sys; d=json.load(sys.stdin); print(d["id"], d["name"], d["price"])') || fail "GET /items/7 failed"
[ "$item" = "7 Item-7 9.99" ] || fail "GET /items/7 returned '$item'"
step "GET /items/7 -> $item"
code=$(curl -s -o /dev/null -w '%{http_code}' "$A/items/0"); [ "$code" = 400 ] || fail "/items/0 answered HTTP $code instead of 400"
code=$(curl -s -o /dev/null -w '%{http_code}' "$A/items/abc"); [ "$code" = 422 ] || fail "/items/abc answered HTTP $code instead of 422"
step "invalid input is rejected (400 and 422)"
echo=$(curl -fsS -H "$JSON" -d '{"text":"hello"}' "$A/echo" | py 'import json,sys; d=json.load(sys.stdin); print(d["length"], d["upper"])') || fail "POST /echo failed"
[ "$echo" = "5 HELLO" ] || fail "POST /echo returned '$echo'"
step "POST /echo -> $echo"
docker compose exec -T fastapi test -s /var/log/fastapi/app.log || fail "the application log file is empty"
step "the application writes its log file"
echo "FastAPI functional smoke test passed"
