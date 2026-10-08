#!/usr/bin/env bash
# Start a project, wait until it is up, fail on crashed/unhealthy containers, tear down.
# Usage: scripts/smoke.sh <project-dir> [wait-timeout-seconds]
#
# `docker compose up --wait` treats one-shot jobs that exit 0 (certificate setup,
# DB migrations, ...) as failures, so this script does its own waiting:
#   - exited with 0            -> done (one-shot job)
#   - exited non-zero          -> failure
#   - restarting / unhealthy   -> failure
#   - health "starting"        -> keep waiting
#   - running (no healthcheck) or healthy -> ok
# A project may ship an executable smoke-test.sh (functional test); it runs once everything is up.
set -uo pipefail
dir=$1; timeout=${2:-300}
root=$(cd "$(dirname "$0")/.." && pwd)
# SMOKE_BIND=1 runs the project with host directories (compose.bind.yaml) instead of named volumes
if [ "${SMOKE_BIND:-}" = "1" ]; then export COMPOSE_FILE=compose.yaml:compose.bind.yaml BIND=1; fi
# SMOKE_VARIANT=<name> adds compose.<name>.yaml (e.g. the seaweedfs/garage object-store variants)
if [ -n "${SMOKE_VARIANT:-}" ]; then
  if [ ! -f "$dir/compose.$SMOKE_VARIANT.yaml" ]; then echo "$dir has no variant '$SMOKE_VARIANT' - skipping"; exit 0; fi
  export COMPOSE_FILE="${COMPOSE_FILE:-compose.yaml}:compose.$SMOKE_VARIANT.yaml"
fi
"$root/scripts/prepare-dirs.sh" "$dir"
cd "$dir" || exit 1

state() {
  docker compose ps -a --format json | python3 -c '
import json, sys
raw = sys.stdin.read().strip()
rows = [json.loads(l) for l in raw.splitlines() if l.strip()] if raw.startswith("{") else (json.loads(raw) if raw else [])
status, bad, pending = "ok", [], []
if not rows:
    print("pending no containers yet"); sys.exit()
for r in rows:
    name, st, code, health = r.get("Name"), r.get("State"), r.get("ExitCode", 0), r.get("Health", "")
    if st == "exited":
        if code != 0: bad.append(f"{name} exited with {code}")
    elif st in ("restarting", "dead"): bad.append(f"{name} is {st}")
    elif st == "created": pending.append(f"{name} created")
    elif health == "unhealthy": bad.append(f"{name} unhealthy")
    elif health == "starting": pending.append(f"{name} health starting")
if bad: print("bad " + "; ".join(bad))
elif pending: print("pending " + "; ".join(pending))
else: print("ok all containers up")
'
}

rc=0
docker compose up -d --build || rc=1
if [ $rc -eq 0 ]; then
  deadline=$((SECONDS + timeout))
  stable=0
  while :; do
    out=$(state); kind=${out%% *}
    case $kind in
      ok)      stable=$((stable + 1)); [ $stable -ge 2 ] && { echo "$out"; break; } ;;
      bad)     echo "::error::$dir: ${out#bad }"; rc=1; break ;;
      *)       stable=0 ;;
    esac
    if [ $SECONDS -ge $deadline ]; then echo "::error::$dir: not ready after ${timeout}s (${out#* })"; rc=1; break; fi
    sleep 5
  done
fi

# Optional functional test shipped with the project (runs against the running stack)
if [ $rc -eq 0 ] && [ -x ./smoke-test.sh ]; then
  echo "running $dir/smoke-test.sh"
  ./smoke-test.sh || rc=1
fi

docker compose ps -a
if [ $rc -ne 0 ]; then
  for c in $(docker compose ps -a -q); do
    echo "--- health of $(docker inspect -f '{{.Name}}' "$c"):"
    docker inspect -f '{{json .State.Health}}' "$c" | cut -c1-1500
  done
  docker compose logs --tail=100
fi
docker compose --profile '*' down -v --remove-orphans >/dev/null 2>&1
exit $rc
