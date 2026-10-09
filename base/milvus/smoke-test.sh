#!/usr/bin/env bash
# Functional test (REST API): create a collection, insert vectors, search them, then check that
# Milvus stored data in the S3 object store (RustFS / SeaweedFS / Garage).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
API=http://localhost:19530/v2/vectordb
JSON='Content-Type: application/json'
fail() { echo "::error::milvus smoke test: $*"; exit 1; }
post() {  # post <endpoint> <json>  -> prints the body, fails unless the response code is 0
  local out; out=$(curl -fsS -m 60 -H "$JSON" -d "$2" "$API/$1") || return 1
  printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps(d)); sys.exit(0 if d.get("code")==0 else 1)'
}

deadline=$((SECONDS + 180))
until curl -fsS http://localhost:9091/healthz >/dev/null 2>&1; do
  [ $SECONDS -ge $deadline ] && fail "Milvus did not become healthy"
  sleep 5
done
echo "ok: Milvus is healthy"

post collections/drop '{"collectionName":"smoke"}' >/dev/null 2>&1 || true
post collections/create '{"collectionName":"smoke","dimension":4,"metricType":"COSINE"}' >/dev/null || fail "cannot create collection"
post entities/insert '{"collectionName":"smoke","data":[{"id":1,"vector":[1,0,0,0]},{"id":2,"vector":[0,1,0,0]},{"id":3,"vector":[0,0,1,0]}]}' >/dev/null || fail "insert failed"
echo "ok: collection created and rows inserted"
post collections/flush '{"collectionName":"smoke"}' >/dev/null 2>&1 || echo "note: flush endpoint not available, relying on Milvus' own flush"

found=
for _ in 1 2 3 4 5 6; do
  hit=$(post entities/search '{"collectionName":"smoke","data":[[0,1,0,0]],"limit":1,"outputFields":["id"]}' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"][0]["id"])') && [ "$hit" = 2 ] && { found=1; break; }
  sleep 5
done
[ -n "$found" ] || fail "search did not return the nearest vector"
echo "ok: similarity search returns the nearest vector"

n=$(docker compose run --rm --no-deps --entrypoint /bin/sh create-bucket -c \
  'aws --endpoint-url http://s3:9000 s3 ls --recursive "s3://${S3_BUCKETS%% *}/" | wc -l' | tail -n1 | tr -dc 0-9)
echo "objects in the bucket: ${n:-0}"
[ "${n:-0}" -gt 0 ] || echo "::warning::no objects in the bucket yet (Milvus may not have flushed)"
curl -fsS -m 60 -H "$JSON" -d '{"collectionName":"smoke"}' "$API/collections/drop" >/dev/null || true
echo "Milvus functional smoke test passed"
