#!/usr/bin/env bash
# Start a project, wait for health, fail on exited/unhealthy containers, tear down.
# Usage: scripts/smoke.sh <project-dir> [wait-timeout-seconds]
set -uo pipefail
dir=$1; timeout=${2:-300}
root=$(cd "$(dirname "$0")/.." && pwd)
"$root/scripts/prepare-dirs.sh" "$dir"
cd "$dir" || exit 1
rc=0
docker compose up -d --build --wait --wait-timeout "$timeout" || rc=1
docker compose ps -a
# non-zero exited containers or unhealthy ones are failures (one-shot init jobs exiting 0 are fine)
bad=$(docker compose ps -a --format '{{.Name}} {{.State}} {{.ExitCode}} {{.Health}}' | awk '($2=="exited" && $3!=0) || $4=="unhealthy" || $2=="restarting"')
if [ -n "$bad" ]; then echo "::error::unhealthy/failed containers in $dir:"; echo "$bad"; rc=1; fi
if [ $rc -ne 0 ]; then
  for c in $(docker compose ps -a -q); do
    echo "--- health of $(docker inspect -f '{{.Name}}' "$c"):"
    docker inspect -f '{{json .State.Health}}' "$c" | cut -c1-1500
  done
  docker compose logs --tail=100
fi
docker compose down -v --remove-orphans >/dev/null 2>&1
exit $rc
