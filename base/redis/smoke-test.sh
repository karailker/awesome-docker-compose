#!/usr/bin/env bash
# Functional test: strings, counters, lists and key expiry through redis-cli.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="redis smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
r() { docker compose exec -T redis redis-cli "$@"; }

retry 60 "Redis answers PING" r ping
[ "$(r set smoke:k hello)" = OK ] || fail "SET failed"
[ "$(r get smoke:k)" = hello ] || fail "GET returned another value"
r del smoke:n smoke:list >/dev/null
[ "$(r incr smoke:n)" = 1 ] && [ "$(r incrby smoke:n 4)" = 5 ] || fail "INCR / INCRBY failed"
r rpush smoke:list a b c >/dev/null
[ "$(r lrange smoke:list 0 -1 | paste -sd, -)" = "a,b,c" ] || fail "list operations failed"
r set smoke:ttl x ex 1 >/dev/null; sleep 2
[ "$(r exists smoke:ttl)" = 0 ] || fail "key did not expire"
r del smoke:k smoke:n smoke:list >/dev/null
step "string, counter, list and expiry commands work"
echo "Redis functional smoke test passed"
