#!/usr/bin/env bash
# Functional test: Grafana and Prometheus are healthy, the provisioned data sources work and Prometheus scrapes itself.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="grafana smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
GF=http://localhost:3000; PROM=http://localhost:9090
AUTH="${GF_ADMIN_USER:-admin}:${GF_ADMIN_PASSWORD:-admin}"

retry 120 "Grafana is healthy" curl -fsS "$GF/api/health"
retry 120 "Prometheus is ready" curl -fsS "$PROM/-/ready"
up() { curl -fsS -G "$PROM/api/v1/query" --data-urlencode 'query=up{job="prometheus"}' | py 'import json,sys; r=json.load(sys.stdin)["data"]["result"]; sys.exit(0 if r and r[0]["value"][1]=="1" else 1)'; }
retry 120 "Prometheus scrapes itself (up{job=\"prometheus\"} = 1)" up
# the data sources from grafana/provisioning/datasources must exist and be healthy
uids=$(curl -fsS -u "$AUTH" "$GF/api/datasources" | py 'import json,sys; print(" ".join(d["uid"] for d in json.load(sys.stdin)))') || fail "cannot list the data sources"
[ -n "$uids" ] || fail "no data source is provisioned"
for uid in $uids; do
  check() { curl -fsS -u "$AUTH" "$GF/api/datasources/uid/$uid/health" | py 'import json,sys; sys.exit(0 if json.load(sys.stdin)["status"]=="OK" else 1)'; }
  retry 60 "Grafana data source '$uid' is healthy" check
done
# a query through Grafana reaches Prometheus
uid=$(curl -fsS -u "$AUTH" "$GF/api/datasources" | py 'import json,sys; print([d["uid"] for d in json.load(sys.stdin) if d["type"]=="prometheus"][0])') || fail "no Prometheus data source"
curl -fsS -u "$AUTH" -G "$GF/api/datasources/proxy/uid/$uid/api/v1/query" --data-urlencode 'query=up' | grep -q '"status":"success"' || fail "query through Grafana failed"
step "a query through Grafana reaches Prometheus"
echo "Grafana functional smoke test passed"
