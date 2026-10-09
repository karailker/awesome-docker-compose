#!/usr/bin/env bash
# Functional test: run the init job, create a table as the application user, write and read rows in a transaction.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="cockroachdb smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
DB=${COCKROACH_DATABASE:-appdb}
sql() { docker compose exec -T cockroach cockroach sql --insecure --host=localhost:26257 "$@"; }

retry 180 "CockroachDB is ready" curl -fsS "http://localhost:${COCKROACH_HTTP_PORT:-8088}/health?ready=1"
# the init profile creates the database and the application user
docker compose --profile init run --rm initdb >/dev/null 2>&1 || fail "the init job failed"
step "init job created database $DB and user ${COCKROACH_USER:-app}"
sql -d "$DB" -e "DROP TABLE IF EXISTS smoke; CREATE TABLE smoke (id INT PRIMARY KEY, amount DECIMAL(8,2)); BEGIN; INSERT INTO smoke VALUES (1,10.50),(2,20.25),(3,5.00); COMMIT;" >/dev/null || fail "cannot create and fill a table"
total=$(sql -d "$DB" --format=csv -e 'SELECT sum(amount) FROM smoke' | tail -n1 | tr -d '\r') || fail "aggregate failed"
[ "$total" = 35.75 ] || fail "sum is $total instead of 35.75"
step "transaction committed, sum is $total"
sql -d "$DB" -e 'DROP TABLE smoke' >/dev/null
echo "CockroachDB functional smoke test passed"
