#!/usr/bin/env bash
# Functional test: GitLab is ready, root can get an API token with the password from compose.yaml,
# and a project can be created through the API.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="gitlab smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
BASE=http://localhost:8090
PW=$(sed -n 's/^ *GITLAB_ROOT_PASSWORD: *//p' compose.yaml | head -n1)

# /-/readiness is limited to the monitoring IP allowlist (requests via the published port are rejected),
# so wait for the sign-in page instead (200, or a redirect to the configured external_url)
sign_in_page() { code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/users/sign_in"); [ "$code" = 200 ] || [ "$code" = 302 ]; }
retry 900 "GitLab answers (sign-in page)" sign_in_page
token=$(curl -fsS -m 60 "$BASE/oauth/token" -d grant_type=password -d username=root --data-urlencode "password=$PW" \
  | py 'import json,sys; print(json.load(sys.stdin)["access_token"])') || fail "cannot sign in as root"
step "root signed in"
auth="Authorization: Bearer $token"
curl -fsS -m 60 -H "$auth" -d name=smoke -d initialize_with_readme=true "$BASE/api/v4/projects" >/dev/null || fail "cannot create a project"
curl -fsS -m 60 -H "$auth" "$BASE/api/v4/projects?search=smoke" | grep -q '"name":"smoke"' || fail "project not found"
step "project created through the API"
echo "GitLab functional smoke test passed"
