#!/usr/bin/env bash
# Functional test through the management API: declare a queue, publish a message and read it back.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="rabbitmq smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
U=${RABBITMQ_DEFAULT_USER:-user}; P=${RABBITMQ_DEFAULT_PASS:-password}
API=http://localhost:15672/api
api() { curl -fsS -m 30 -u "$U:$P" -H "$JSON" "$@"; }

retry 180 "management API answers" api "$API/overview"
api -X PUT -d '{"durable":true,"auto_delete":false}' "$API/queues/%2F/smoke" || fail "cannot declare the queue"
pub=$(api -X POST -d '{"properties":{},"routing_key":"smoke","payload":"hello rabbit","payload_encoding":"string"}' "$API/exchanges/%2F/amq.default/publish") || fail "publish failed"
printf '%s' "$pub" | grep -q '"routed":true' || fail "the message was not routed: $pub"
step "message published and routed to the queue"
got=$(api -X POST -d '{"count":1,"ackmode":"ack_requeue_false","encoding":"auto"}' "$API/queues/%2F/smoke/get" | py 'import json,sys; print(json.load(sys.stdin)[0]["payload"])') || fail "reading the message failed"
[ "$got" = "hello rabbit" ] || fail "received '$got'"
step "message consumed: $got"
api -X DELETE "$API/queues/%2F/smoke" >/dev/null || true
# a wrong password is refused
code=$(curl -s -o /dev/null -w '%{http_code}' -u "$U:definitely-wrong" "$API/overview")
[ "$code" = 401 ] || fail "wrong password answered HTTP $code instead of 401"
step "a wrong password is refused (HTTP 401)"
echo "RabbitMQ functional smoke test passed"
