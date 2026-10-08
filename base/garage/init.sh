#!/usr/bin/env bash
# One-time Garage bootstrap for a single-node setup: assign the cluster layout,
# create an access key and (optionally) a bucket.
# Usage: ./init.sh [bucket-name]   -> prints the access key / secret key
set -euo pipefail
cd "$(dirname "$0")"
g() { docker compose exec -T garage /garage "$@"; }

for _ in $(seq 1 30); do g status >/dev/null 2>&1 && break; sleep 2; done
NODE_ID=$(g node id -q 2>/dev/null | cut -d@ -f1)
if g status 2>/dev/null | grep -q "NO ROLE ASSIGNED"; then
  VERSION=$(g layout show 2>/dev/null | sed -n 's/.*[Cc]urrent cluster layout version: *//p' | head -1)
  g layout assign -z dc1 -c 1G "$NODE_ID"
  g layout apply --version "$(( ${VERSION:-0} + 1 ))"
else
  echo "Layout already configured."
fi
KEY_NAME="${GARAGE_KEY_NAME:-dev-key}"
g key info "$KEY_NAME" >/dev/null 2>&1 || g key create "$KEY_NAME"
g key allow --create-bucket "$KEY_NAME" >/dev/null
if [ -n "${1:-}" ]; then
  g bucket info "$1" >/dev/null 2>&1 || g bucket create "$1"
  g bucket allow --read --write --owner "$1" --key "$KEY_NAME"
fi
g key info --show-secret "$KEY_NAME"
