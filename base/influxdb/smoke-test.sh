#!/usr/bin/env bash
# Functional test: write a point with the line protocol and read it back with Flux.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="influxdb smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
I=http://localhost:${INFLUXDB_PORT:-8086}
ORG=${INFLUXDB_ORG:-my-org}; BUCKET=${INFLUXDB_BUCKET:-default}; TOKEN=${INFLUXDB_ADMIN_TOKEN:-local-dev-token}

health() { curl -fsS "$I/health" | grep -q '"status":"pass"'; }
retry 180 "InfluxDB is healthy" health
m="smoke_$(date +%s)"
curl -fsS -m 30 -X POST "$I/api/v2/write?org=$ORG&bucket=$BUCKET&precision=s" -H "Authorization: Token $TOKEN" \
  --data-binary "$m,host=ci value=42.5 $(date +%s)" || fail "write failed"
step "point written to $m"
read_back() {
  curl -fsS -m 30 -X POST "$I/api/v2/query?org=$ORG" -H "Authorization: Token $TOKEN" -H 'Content-Type: application/vnd.flux' -H 'Accept: application/csv' \
    --data-binary "from(bucket: \"$BUCKET\") |> range(start: -10m) |> filter(fn: (r) => r._measurement == \"$m\")" | grep -q '42.5'
}
retry 60 "the point is returned by a Flux query" read_back
# a wrong token is refused
code=$(curl -s -o /dev/null -w '%{http_code}' -H 'Authorization: Token wrong' "$I/api/v2/buckets")
[ "$code" = 401 ] || fail "a wrong token answered HTTP $code instead of 401"
step "a wrong token is refused (HTTP 401)"
echo "InfluxDB functional smoke test passed"
