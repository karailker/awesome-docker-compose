#!/usr/bin/env bash
# Functional test: send a trace, a metric and a log line through the OpenTelemetry Collector
# and read each of them back from Tempo, Prometheus and Loki; check the Grafana provisioning.
# Run by scripts/smoke.sh after the stack is up (working directory: this directory).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck disable=SC1091
[ -f .env ] && set -a && . ./.env && set +a
OTLP=http://localhost:${OTLP_HTTP_PORT:-4318}
TEMPO=http://localhost:${TEMPO_PORT:-3200}
PROM=http://localhost:${PROMETHEUS_PORT:-9090}
LOKI=http://localhost:${LOKI_PORT:-3100}
GRAFANA=http://localhost:${GRAFANA_PORT:-3000}
GF_AUTH="${GF_ADMIN_USER:-admin}:${GF_ADMIN_PASSWORD:-admin}"

fail() { echo "::error::lgtm smoke test: $*"; exit 1; }
# retry <seconds> <description> <command...>
retry() {
  local secs=$1 what=$2; shift 2
  local deadline=$((SECONDS + secs))
  until "$@" >/dev/null 2>&1; do
    [ $SECONDS -ge $deadline ] && fail "$what (timeout after ${secs}s)"
    sleep 3
  done
  echo "ok: $what"
}

retry 120 "Grafana is healthy" curl -fsS "$GRAFANA/api/health"
retry 60 "Loki is ready" curl -fsS "$LOKI/ready"
retry 60 "Tempo is ready" curl -fsS "$TEMPO/ready"
retry 60 "OTLP/HTTP endpoint accepts requests" curl -sS -o /dev/null -X POST "$OTLP/v1/traces" -H 'Content-Type: application/json' -d '{}'

tid=$(openssl rand -hex 16); sid=$(openssl rand -hex 8)
now=$(date +%s); start=$((now * 1000000000)); end=$((start + 2000000))
res='"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"smoke-test"}}]}'
post() { curl -fsS -m 10 -X POST "$OTLP/v1/$1" -H 'Content-Type: application/json' -d "$2" >/dev/null || fail "POST /v1/$1 failed"; }

post traces "{\"resourceSpans\":[{$res,\"scopeSpans\":[{\"scope\":{\"name\":\"smoke\"},\"spans\":[{\"traceId\":\"$tid\",\"spanId\":\"$sid\",\"name\":\"smoke-span\",\"kind\":1,\"startTimeUnixNano\":\"$start\",\"endTimeUnixNano\":\"$end\"}]}]}]}"
post metrics "{\"resourceMetrics\":[{$res,\"scopeMetrics\":[{\"scope\":{\"name\":\"smoke\"},\"metrics\":[{\"name\":\"smoke_test_gauge\",\"gauge\":{\"dataPoints\":[{\"asDouble\":42,\"timeUnixNano\":\"$start\"}]}}]}]}]}"
post logs "{\"resourceLogs\":[{$res,\"scopeLogs\":[{\"scope\":{\"name\":\"smoke\"},\"logRecords\":[{\"timeUnixNano\":\"$start\",\"severityText\":\"INFO\",\"body\":{\"stringValue\":\"smoke-log-line $tid\"},\"traceId\":\"$tid\",\"spanId\":\"$sid\"}]}]}]}"

retry 90 "trace $tid is stored in Tempo" curl -fsS "$TEMPO/api/traces/$tid"
prom_has() { curl -fsS -G "$PROM/api/v1/query" --data-urlencode "query=$1" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["result"] else 1)'; }
retry 90 "metric smoke_test_gauge is queryable in Prometheus" prom_has smoke_test_gauge
loki_has() { curl -fsS -G "$LOKI/loki/api/v1/query_range" --data-urlencode 'query={service_name="smoke-test"} |= "smoke-log-line"' --data-urlencode "start=$((now - 300))000000000" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["result"] else 1)'; }
retry 90 "log line is queryable in Loki" loki_has

for uid in prometheus loki tempo; do
  retry 60 "Grafana datasource $uid is healthy" bash -c "curl -fsS -u '$GF_AUTH' '$GRAFANA/api/datasources/uid/$uid/health' | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)[\"status\"]==\"OK\" else 1)'"
done
retry 60 "Grafana dashboard 'LGTM overview' is provisioned" bash -c "curl -fsS -u '$GF_AUTH' '$GRAFANA/api/dashboards/uid/lgtm-overview' | grep -q 'LGTM overview'"
# Optional (SMOKE_DEMO=1, used by CI): the "demo" profile generates traces, metrics and logs with telemetrygen
if [ "${SMOKE_DEMO:-}" = "1" ]; then
  DEMO_DURATION=2m docker compose --profile demo up -d telemetrygen-traces telemetrygen-metrics telemetrygen-logs >/dev/null 2>&1 \
    || fail "could not start the demo profile"
  tempo_has_demo() { curl -fsS -G "$TEMPO/api/search" --data-urlencode 'q={ resource.service.name = "demo-traces" }' | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("traces") else 1)'; }
  retry 120 "demo traces are searchable in Tempo" tempo_has_demo
  loki_demo() { curl -fsS -G "$LOKI/loki/api/v1/query_range" --data-urlencode 'query={service_name="demo-logs"}' --data-urlencode "start=$(( $(date +%s) - 600 ))000000000" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["result"] else 1)'; }
  retry 120 "demo logs are queryable in Loki" loki_demo
  prom_has_demo() { curl -fsS -G "$PROM/api/v1/query" --data-urlencode 'query={job="demo-metrics"}' | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin)["data"]["result"] else 1)'; }
  retry 120 "demo metrics are queryable in Prometheus" prom_has_demo
fi
echo "LGTM functional smoke test passed"
