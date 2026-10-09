#!/usr/bin/env bash
# Functional test: Langfuse is healthy, the headless-initialised project accepts a trace through the
# public ingestion API (web -> Redis -> worker -> ClickHouse / S3) and returns it again.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="langfuse smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
BASE=http://localhost:${LANGFUSE_PORT:-3000}
AUTH="${LANGFUSE_PUBLIC_KEY:-pk-lf-demo}:${LANGFUSE_SECRET_KEY:-sk-lf-demo}"

retry 300 "Langfuse web is healthy" curl -fsS "$BASE/api/public/health"
retry 120 "API key of the initial project is accepted" curl -fsS -u "$AUTH" "$BASE/api/public/projects"

id="smoke-$(date +%s)-$RANDOM"
ts=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
body="{\"batch\":[{\"id\":\"ev-$id\",\"type\":\"trace-create\",\"timestamp\":\"$ts\",\"body\":{\"id\":\"$id\",\"name\":\"smoke-trace\",\"timestamp\":\"$ts\",\"input\":\"ping\",\"output\":\"pong\"}}]}"
resp=$(curl -sS -m 30 -u "$AUTH" -H "$JSON" -d "$body" "$BASE/api/public/ingestion") || fail "ingestion request failed"
printf '%s' "$resp" | py 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if not d.get("errors") else 1)' || fail "ingestion reported errors: $resp"
step "trace $id accepted"
trace_found() { curl -fsS -m 30 -u "$AUTH" "$BASE/api/public/traces/$id" | grep -q "smoke-trace"; }
retry 180 "trace $id can be read back (worker wrote it to ClickHouse)" trace_found
echo "Langfuse functional smoke test passed"
