#!/usr/bin/env bash
# Prepare a project directory for CI / local runs:
#   - copy .env.example to .env when present
#   - with BIND=1, create the host directories used by compose.bind.yaml
# Usage: [BIND=1] [DATA_DIR=dir] scripts/prepare-dirs.sh <project-dir>
set -euo pipefail
cd "$1"
if [ -f .env.example ] && [ ! -f .env ]; then cp .env.example .env; fi
if [ "${BIND:-}" = "1" ] && [ -f compose.bind.yaml ]; then
  data_dir=${DATA_DIR:-.}
  # grep exits 1 when there is no match, which is fine
  { grep -hoE 'device: *\$\{DATA_DIR:-\.\}/[^ ]+' compose.bind.yaml || true; } | sed -E 's#device: *\$\{DATA_DIR:-\.\}/##' | sort -u | while read -r d; do
    mkdir -p "$data_dir/$d"
  done
fi
