#!/usr/bin/env bash
# Fail when a compose file uses a floating image tag (":latest", "-latest" or no tag at all).
# Exceptions live in scripts/pin-exceptions.txt (one image reference per line, with a reason after "#").
# Usage: scripts/check-pins.sh [compose files...]   (default: every compose.yaml under base/ and stacks/)
set -euo pipefail
cd "$(dirname "$0")/.."
files=("$@")
if [ ${#files[@]} -eq 0 ]; then mapfile -t files < <(find base stacks -name compose.yaml | sort); fi
rc=0
for f in "${files[@]}"; do
  dir=$(dirname "$f")
  while read -r img; do
    [ -z "$img" ] && continue
    # images built locally from a Dockerfile are not pulled
    case "$img" in fastapi-example:*) continue ;; esac
    name=${img##*/}
    if [[ "$name" != *:* ]] || [[ "$name" == *:latest ]] || [[ "$name" == *-latest ]]; then
      if grep -qxE "$(printf '%s' "$img" | sed 's/[][\.*^$/]/\\&/g')[[:space:]]*(#.*)?" scripts/pin-exceptions.txt 2>/dev/null; then continue; fi
      echo "::error file=$f::floating image tag: $img (pin a version or add it to scripts/pin-exceptions.txt with a reason)"
      rc=1
    fi
  done < <(cd "$dir" && docker compose --env-file /dev/null --profile '*' config --images 2>/dev/null | sort -u)
done
exit $rc
