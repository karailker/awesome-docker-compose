#!/usr/bin/env bash
# Functional test: create a table, insert rows, aggregate them and check that the network login needs the right password.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="postgres smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
U=${POSTGRES_USER:-myuser}; D=${POSTGRES_DB:-mydatabase}
sql() { docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$U" -d "$D" -tA "$@"; }

retry 120 "PostgreSQL accepts connections" sql -c 'select 1'
sql -c "drop table if exists smoke; create table smoke (id int primary key, amount numeric(8,2)); insert into smoke values (1, 10.50), (2, 20.25), (3, 5.00)" >/dev/null || fail "cannot create and fill a table"
total=$(sql -c 'select sum(amount) from smoke') || fail "aggregate query failed"
[ "$total" = 35.75 ] || fail "sum is $total instead of 35.75"
step "table created, rows inserted, sum is $total"
sql -c 'drop table smoke' >/dev/null
# Authentication over the network: the image trusts loopback connections inside the container, so use the
# service name (its network address). The right password works, a wrong one is refused.
P=${POSTGRES_PASSWORD:-mypassword}
net() { docker compose exec -T -e PGPASSWORD="$1" postgres psql -h postgres -U "$U" -d "$D" -tA -c 'select 1'; }
[ "$(net "$P" 2>/dev/null)" = 1 ] || fail "the right password was refused over the network"
if net definitely-wrong >/dev/null 2>&1; then fail "a wrong password was accepted over the network"; fi
step "network connections need the right password"
echo "PostgreSQL functional smoke test passed"
