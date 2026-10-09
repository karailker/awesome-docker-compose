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

retry 900 "GitLab is ready" curl -fsS "$BASE/-/readiness"
token=$(curl -fsS -m 60 "$BASE/oauth/token" -d grant_type=password -d username=root --data-urlencode "password=$PW" \
  | py 'import json,sys; print(json.load(sys.stdin)["access_token"])') || fail "cannot sign in as root"
step "root signed in"
auth="Authorization: Bearer $token"
curl -fsS -m 60 -H "$auth" -d name=smoke -d initialize_with_readme=true "$BASE/api/v4/projects" >/dev/null || fail "cannot create a project"
curl -fsS -m 60 -H "$auth" "$BASE/api/v4/projects?search=smoke" | grep -q '"name":"smoke"' || fail "project not found"
step "project created through the API"
echo "GitLab functional smoke test passed"
