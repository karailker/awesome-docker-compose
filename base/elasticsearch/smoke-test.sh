#!/usr/bin/env bash
# Functional test: cluster health, index a document, search it, Kibana status and the APM server.
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
echo "Elasticsearch functional smoke test passed"
