#!/usr/bin/env bash
# Functional test: create a table as the application user, insert rows and aggregate them.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="mysql smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
U=${MYSQL_USER:-user}; P=${MYSQL_PASSWORD:-password}; D=${MYSQL_DATABASE:-mydb}
sql() { docker compose exec -T mysql mysql -u"$U" -p"$P" "$D" -N -B -e "$1"; }

# the healthcheck pings the socket; the TCP port only opens after the init scripts finished
retry 180 "MySQL accepts the application user" sql 'select 1'
sql "drop table if exists smoke; create table smoke (id int primary key, amount decimal(8,2)); insert into smoke values (1,10.50),(2,20.25),(3,5.00)" || fail "cannot create and fill a table"
total=$(sql 'select sum(amount) from smoke') || fail "aggregate query failed"
[ "$total" = 35.75 ] || fail "sum is $total instead of 35.75"
step "table created, rows inserted, sum is $total"
sql 'drop table smoke' >/dev/null
echo "MySQL functional smoke test passed"
