#!/usr/bin/env bash
# Scan every image referenced by the compose files with Trivy and print a Markdown summary.
# Never fails because of findings in upstream images (set FAIL_ON_FINDINGS=1 to change that).
# Usage: [TRIVY=trivy] scripts/scan-images.sh [image ...]   (default: all images of base/ and stacks/)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
trivy=${TRIVY:-trivy}
images=("$@")
if [ ${#images[@]} -eq 0 ]; then
  mapfile -t images < <(for f in $(find base stacks -name compose.yaml | sort); do
    (cd "$(dirname "$f")" && docker compose --env-file /dev/null --profile '*' config --images 2>/dev/null)
  done | sort -u | grep -v '^fastapi-example')
fi
echo "| Image | Critical | High | Fixable |"
echo "|---|---:|---:|---:|"
total=0
for img in "${images[@]}"; do
  if ! json=$($trivy image --quiet --scanners vuln --severity HIGH,CRITICAL --format json "$img" 2>/dev/null); then
    echo "| \`$img\` | scan failed | | |"; continue
  fi
  read -r crit high fixable < <(printf '%s' "$json" | python3 -c '
import json, sys
d = json.load(sys.stdin)
c = h = f = 0
for r in d.get("Results", []) or []:
    for v in r.get("Vulnerabilities", []) or []:
        c += v["Severity"] == "CRITICAL"; h += v["Severity"] == "HIGH"; f += bool(v.get("FixedVersion"))
print(c, h, f)')
  echo "| \`$img\` | $crit | $high | $fixable |"
  total=$((total + crit))
done
[ "${FAIL_ON_FINDINGS:-0}" = "1" ] && [ "$total" -gt 0 ] && exit 1
exit 0
