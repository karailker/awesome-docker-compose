#!/usr/bin/env bash
# Create the host directories that compose.yaml bind-mounts via `device: ./dir`,
# and copy .env.example to .env when present. Usage: scripts/prepare-dirs.sh <project-dir>
set -euo pipefail
cd "$1"
[ -f .env.example ] && [ ! -f .env ] && cp .env.example .env
grep -hoE 'device: *\./[^ ]+' compose.yaml 2>/dev/null | sed -E 's/device: *//' | sort -u | while read -r d; do
  mkdir -p "$d"
done
exit 0
