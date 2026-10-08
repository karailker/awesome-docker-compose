#!/usr/bin/env bash
# Create the host directories that compose.yaml bind-mounts via `device: ./dir`,
# and copy .env.example to .env when present. Usage: scripts/prepare-dirs.sh <project-dir>
set -euo pipefail
cd "$1"
if [ -f .env.example ] && [ ! -f .env ]; then cp .env.example .env; fi
# grep exits 1 when a project has no bind volumes, which is fine
{ grep -hoE 'device: *\./[^ ]+' compose.yaml 2>/dev/null || true; } | sed -E 's/device: *//' | sort -u | while read -r d; do
  mkdir -p "$d"
done
