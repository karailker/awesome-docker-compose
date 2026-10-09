#!/usr/bin/env bash
# Functional test: create a topic, produce messages and consume them again.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="kafka smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"

BS=localhost:29092 # inside the container
kafka() { docker compose exec -T kafka "$@"; }

retry 120 "broker answers" kafka kafka-broker-api-versions --bootstrap-server "$BS"
kafka kafka-topics --bootstrap-server "$BS" --create --if-not-exists --topic smoke --partitions 1 --replication-factor 1 >/dev/null || fail "cannot create topic"
step "topic created"
printf 'one\ntwo\nthree\n' | kafka kafka-console-producer --bootstrap-server "$BS" --topic smoke >/dev/null 2>&1 || fail "produce failed"
got=$(kafka kafka-console-consumer --bootstrap-server "$BS" --topic smoke --from-beginning --max-messages 3 --timeout-ms 30000 2>/dev/null | tr -d '\r' | paste -sd, -)
[ "$got" = "one,two,three" ] || fail "consumed '$got' instead of one,two,three"
step "produced and consumed 3 messages"
echo "Kafka functional smoke test passed"
