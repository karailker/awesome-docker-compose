#!/usr/bin/env bash
# Helpers shared by the per-project smoke-test.sh scripts. Source it:
#   # shellcheck disable=SC1091
#   . "$(dirname "$0")/../../scripts/smoke-lib.sh"
# Usage in a test: set NAME, then use fail / retry / py / step.
NAME=${NAME:-smoke test}
export JSON='Content-Type: application/json'

fail() { echo "::error::$NAME: $*"; exit 1; }
step() { echo "ok: $*"; }
py() { python3 -c "$@"; }

# retry <seconds> <description> <command...>: run the command every 5 s until it succeeds
retry() {
  local secs=$1 what=$2; shift 2
  local deadline=$((SECONDS + secs))
  until "$@" >/dev/null 2>&1; do
    [ $SECONDS -ge $deadline ] && fail "$what (timeout after ${secs}s)"
    sleep 5
  done
  step "$what"
}

# load .env of the project (the test runs inside the project directory)
load_env() {
  # shellcheck disable=SC1091
  [ -f .env ] && { set -a; . ./.env; set +a; }
  return 0
}
