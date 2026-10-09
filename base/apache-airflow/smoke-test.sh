#!/usr/bin/env bash
# Functional test: sign in, unpause the example DAG "example_bash_operator", trigger it and wait
# until the CeleryExecutor worker has run it successfully.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="airflow smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
BASE=http://localhost:8080
DAG=example_bash_operator

retry 300 "API server is healthy" curl -fsS "$BASE/api/v2/monitor/health"
token=$(curl -fsS -m 30 -H "$JSON" -d "{\"username\":\"${_AIRFLOW_WWW_USER_USERNAME:-airflow}\",\"password\":\"${_AIRFLOW_WWW_USER_PASSWORD:-airflow}\"}" "$BASE/auth/token" \
  | py 'import json,sys; print(json.load(sys.stdin)["access_token"])') || fail "cannot get a token"
auth="Authorization: Bearer $token"
step "signed in"
dag_known() { curl -fsS -m 30 -H "$auth" "$BASE/api/v2/dags/$DAG"; }
retry 300 "DAG $DAG was parsed by the dag-processor" dag_known
curl -fsS -m 30 -X PATCH -H "$auth" -H "$JSON" -d '{"is_paused":false}' "$BASE/api/v2/dags/$DAG" >/dev/null || fail "cannot unpause the DAG"
run_id=$(curl -fsS -m 30 -H "$auth" -H "$JSON" -d "{\"logical_date\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" "$BASE/api/v2/dags/$DAG/dagRuns" \
  | py 'import json,sys; print(json.load(sys.stdin)["dag_run_id"])') || fail "cannot trigger the DAG"
echo "dag run $run_id triggered"
deadline=$((SECONDS + 600))
while :; do
  state=$(curl -fsS -m 30 -H "$auth" "$BASE/api/v2/dags/$DAG/dagRuns/$run_id" | py 'import json,sys; print(json.load(sys.stdin)["state"])')
  case $state in
    success) break ;;
    failed) fail "dag run failed" ;;
  esac
  [ $SECONDS -ge $deadline ] && fail "dag run still $state after 600s"
  sleep 5
done
step "dag run succeeded"
echo "Airflow functional smoke test passed"
