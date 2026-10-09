#!/usr/bin/env bash
# Functional test over the HTTP interface: create a MergeTree table, insert rows and aggregate them; Tabix answers.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="clickhouse smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
CH=http://localhost:${CLICKHOUSE_HTTP_PORT:-8123}
U=${CLICKHOUSE_USER:-chadmin}; P=${CLICKHOUSE_PASSWORD:-chpass}
q() { curl -fsS -m 60 -u "$U:$P" --data-binary "$1" "$CH/"; }

retry 120 "ClickHouse answers" q 'SELECT 1'
q 'DROP TABLE IF EXISTS smoke' >/dev/null
q 'CREATE TABLE smoke (day Date, country String, amount Float64) ENGINE = MergeTree ORDER BY (country, day)' >/dev/null || fail "cannot create the table"
q "INSERT INTO smoke VALUES ('2026-01-01','DE',10.5), ('2026-01-02','DE',20), ('2026-01-01','TR',5)" >/dev/null || fail "insert failed"
res=$(q "SELECT country, sum(amount) FROM smoke GROUP BY country ORDER BY country FORMAT CSV" | tr -d '"' | paste -sd' ' -) || fail "aggregate failed"
[ "$res" = "DE,30.5 TR,5" ] || fail "aggregation returned '$res'"
step "MergeTree table filled and aggregated ($res)"
q 'DROP TABLE smoke' >/dev/null
code=$(curl -s -o /dev/null -w '%{http_code}' -u "$U:wrong" --data-binary 'SELECT 1' "$CH/")
case "$code" in 401|403|516) ;; *) fail "a wrong password answered HTTP $code" ;; esac
step "a wrong password is refused (HTTP $code)"
retry 60 "Tabix UI answers" curl -fsS -o /dev/null "http://localhost:${TABIX_PORT:-8124}/"
echo "ClickHouse functional smoke test passed"
