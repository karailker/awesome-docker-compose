#!/usr/bin/env bash
# Functional test (REST): create a collection, upsert points and run a similarity search with a payload filter.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="qdrant smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
Q=http://localhost:6333
c() { curl -fsS -m 30 -H "$JSON" "$@"; }

retry 120 "Qdrant is ready" curl -fsS "$Q/readyz"
c -X DELETE "$Q/collections/smoke" >/dev/null 2>&1 || true
c -X PUT "$Q/collections/smoke" -d '{"vectors":{"size":3,"distance":"Cosine"}}' >/dev/null || fail "cannot create the collection"
c -X PUT "$Q/collections/smoke/points?wait=true" -d '{"points":[
  {"id":1,"vector":[1,0,0],"payload":{"kind":"x"}},
  {"id":2,"vector":[0,1,0],"payload":{"kind":"y"}},
  {"id":3,"vector":[0.1,0.9,0],"payload":{"kind":"x"}}]}' >/dev/null || fail "upsert failed"
top=$(c -X POST "$Q/collections/smoke/points/query" -d '{"query":[0,1,0],"limit":1}' | py 'import json,sys; print(json.load(sys.stdin)["result"]["points"][0]["id"])') || fail "search failed"
[ "$top" = 2 ] || fail "nearest point is $top instead of 2"
step "nearest neighbour of [0,1,0] is point $top"
filtered=$(c -X POST "$Q/collections/smoke/points/query" -d '{"query":[0,1,0],"limit":1,"filter":{"must":[{"key":"kind","match":{"value":"x"}}]}}' | py 'import json,sys; print(json.load(sys.stdin)["result"]["points"][0]["id"])') || fail "filtered search failed"
[ "$filtered" = 3 ] || fail "filtered nearest point is $filtered instead of 3"
step "payload filter works (nearest point of kind 'x' is $filtered)"
c -X DELETE "$Q/collections/smoke" >/dev/null
echo "Qdrant functional smoke test passed"
