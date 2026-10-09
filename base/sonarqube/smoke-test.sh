#!/usr/bin/env bash
# Functional test: SonarQube is UP, the default admin can sign in and create + find a project.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="sonarqube smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
API=http://localhost:9000/api
AUTH=admin:admin # SonarQube's default login

is_up() { curl -fsS "$API/system/status" | grep -q '"status":"UP"'; }
retry 300 "status is UP" is_up
curl -fsS -m 30 -u "$AUTH" -X POST "$API/projects/create" -d name=Smoke -d project=smoke >/dev/null || fail "cannot create a project"
curl -fsS -m 30 -u "$AUTH" "$API/projects/search?projects=smoke" | grep -q '"key":"smoke"' || fail "created project not found"
step "project created and found"
curl -fsS -m 30 -u "$AUTH" -X POST "$API/projects/delete" -d project=smoke >/dev/null || true
echo "SonarQube functional smoke test passed"
