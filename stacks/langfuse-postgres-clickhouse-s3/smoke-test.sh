#!/usr/bin/env bash
# Functional test: Langfuse is healthy, the headless-initialised project accepts a trace over OTLP
# (web -> Redis -> worker -> ClickHouse / S3) and returns it through the public API.
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

# Langfuse v4 no longer takes trace-create events on /api/public/ingestion (score events only);
# traces arrive as OpenTelemetry spans on the OTLP endpoint.
tid=$(openssl rand -hex 16); sid=$(openssl rand -hex 8)
start=$(($(date +%s) * 1000000000)); end=$((start + 2000000000))
span="{\"resourceSpans\":[{\"resource\":{\"attributes\":[{\"key\":\"service.name\",\"value\":{\"stringValue\":\"smoke-test\"}}]},\"scopeSpans\":[{\"scope\":{\"name\":\"smoke\"},\"spans\":[{\"traceId\":\"$tid\",\"spanId\":\"$sid\",\"name\":\"smoke-span\",\"kind\":1,\"startTimeUnixNano\":\"$start\",\"endTimeUnixNano\":\"$end\",\"attributes\":[{\"key\":\"langfuse.observation.input\",\"value\":{\"stringValue\":\"ping\"}},{\"key\":\"langfuse.observation.output\",\"value\":{\"stringValue\":\"pong\"}}]}]}]}]}"
code=$(curl -sS -m 30 -o /tmp/lf-otlp.out -w '%{http_code}' -u "$AUTH" -H "$JSON" -H 'x-langfuse-ingestion-version: 4' -d "$span" "$BASE/api/public/otel/v1/traces") || fail "OTLP request failed"
case $code in 2??) step "span $sid of trace $tid accepted over OTLP" ;; *) fail "OTLP ingestion returned HTTP $code: $(head -c 400 /tmp/lf-otlp.out)" ;; esac

# read it back (several API generations; the first one that returns the span wins)
span_found() {
  local p
  for p in "api/public/v2/observations?traceId=$tid" "api/public/observations?traceId=$tid" "api/public/traces/$tid"; do
    curl -fsS -m 30 -u "$AUTH" "$BASE/$p" 2>/dev/null | grep -q "smoke-span" && { echo "read back through /$p"; return 0; }
  done
  return 1
}
retry 180 "the span can be read back (worker wrote it to ClickHouse)" span_found
echo "Langfuse functional smoke test passed"
