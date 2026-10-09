#!/usr/bin/env bash
# Functional test: cluster health, index a document, search it, Kibana status, and an APM transaction
# sent to the APM server that must show up in Elasticsearch (traces-apm* data stream).
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="elasticsearch smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
PW=${ELASTIC_PASSWORD:-elasticpassword}
CA=/usr/share/elasticsearch/config/certs/ca/ca.crt
# curl inside the first node (it has the CA and the node certificates)
es() { docker compose exec -T es01 curl -fsS --cacert "$CA" -u "elastic:$PW" -H "$JSON" "$@"; }

health() { es "https://localhost:9200/_cluster/health?wait_for_status=green&timeout=30s" | grep -q '"status":"green"'; }
retry 300 "cluster is green" health
nodes=$(es "https://localhost:9200/_cat/nodes?h=name" | wc -l)
[ "$nodes" -eq 3 ] || fail "expected 3 nodes, found $nodes"
step "3 nodes in the cluster"
es -X PUT "https://localhost:9200/smoke/_doc/1?refresh=true" -d '{"title":"hello elastic"}' >/dev/null || fail "indexing failed"
hits=$(es "https://localhost:9200/smoke/_search" -d '{"query":{"match":{"title":"hello"}}}' | py 'import json,sys; print(json.load(sys.stdin)["hits"]["total"]["value"])') || fail "search failed"
[ "$hits" = 1 ] || fail "search returned $hits hits"
step "document indexed and found"
es -X DELETE "https://localhost:9200/smoke" >/dev/null || true
kibana_up() { curl -fsS "http://localhost:${KIBANA_PORT:-5601}/api/status" -u "elastic:$PW" | grep -q '"level":"available"'; }
retry 300 "Kibana is available" kibana_up

# APM: send one transaction (intake API v2, NDJSON) and find it in Elasticsearch
APM=http://localhost:${APM_PORT:-8200}
apm_up() { curl -fsS "$APM/" | grep -q '"version"'; }
retry 300 "APM server answers" apm_up
tid=$(openssl rand -hex 16); xid=$(openssl rand -hex 8)
tname="smoke-transaction-$xid"
code=$(printf '%s\n%s\n' \
  '{"metadata":{"service":{"name":"smoke-service","agent":{"name":"smoke","version":"1.0"}}}}' \
  "{\"transaction\":{\"id\":\"$xid\",\"trace_id\":\"$tid\",\"name\":\"$tname\",\"type\":\"request\",\"duration\":12.5,\"result\":\"success\",\"sampled\":true,\"span_count\":{\"started\":0}}}" \
  | curl -sS -m 30 -o /tmp/apm-intake.out -w '%{http_code}' -H 'Content-Type: application/x-ndjson' --data-binary @- "$APM/intake/v2/events") || fail "APM intake request failed"
[ "$code" = 202 ] || fail "APM intake answered HTTP $code: $(head -c 400 /tmp/apm-intake.out)"
step "transaction $tname accepted by the APM server (HTTP 202)"
apm_stored() {
  es "https://localhost:9200/traces-apm*/_search" -d "{\"query\":{\"term\":{\"transaction.id\":\"$xid\"}}}" \
    | py 'import json,sys; sys.exit(0 if json.load(sys.stdin)["hits"]["total"]["value"] >= 1 else 1)'
}
apm_diagnostics() {  # printed when the test fails after the APM step has started
  rc=$?
  [ "$rc" -eq 0 ] && return
  echo "--- APM diagnostics"
  curl -sS -m 10 "$APM/" | head -c 400; echo
  docker compose logs --no-color --tail=60 apm-server 2>&1 | cut -c1-300
  es "https://localhost:9200/_cat/indices/*apm*?v&h=index,docs.count,health" 2>&1 | head -20
  es "https://localhost:9200/_data_stream/*apm*?filter_path=data_streams.name" 2>&1 | head -c 600; echo
}
trap apm_diagnostics EXIT
retry 180 "the transaction is stored in Elasticsearch (traces-apm*)" apm_stored
trap - EXIT
echo "Elasticsearch functional smoke test passed"
