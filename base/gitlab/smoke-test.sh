#!/usr/bin/env bash
# Functional test: GitLab answers, root gets an API token and a project can be created through the API.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="gitlab smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
BASE=http://localhost:${GITLAB_HTTP_PORT:-8090}
EXTERNAL=${GITLAB_EXTERNAL_URL:-http://localhost:8090}
ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD:-S3cureP@ssw0rd_2025}

# /-/readiness is limited to the monitoring IP allowlist (requests via the published port are rejected),
# so wait for the sign-in page instead (200, or a redirect to the configured external_url)
sign_in_page() { code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/users/sign_in"); [ "$code" = 200 ] || [ "$code" = 302 ]; }
retry 900 "GitLab answers (sign-in page)" sign_in_page
# the published port and external_url agree: the sign-in page is served directly, not redirected to another host
code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/users/sign_in")
[ "$code" = 200 ] || fail "the sign-in page answered HTTP $code (a redirect means external_url does not match the published port)"
step "sign-in page served at $BASE (external_url $EXTERNAL)"
# The OAuth password grant is restricted in current GitLab versions, so create a personal access
# token for root inside the container (what an admin would do with the rails console)
token="smoke$(openssl rand -hex 12)"
docker compose exec -T -e SMOKE_TOKEN="$token" gitlab gitlab-rails runner '
attrs = { name: "smoke", scopes: ["api"], expires_at: 1.day.from_now }
attrs[:organization] = Organizations::Organization.default_organization if PersonalAccessToken.column_names.include?("organization_id")
pat = User.find_by_username("root").personal_access_tokens.build(attrs)
pat.set_token(ENV.fetch("SMOKE_TOKEN"))
pat.save!
puts "personal access token created"' || fail "cannot create a personal access token for root"
step "root has an API token"
# the root password comes from GITLAB_ROOT_PASSWORD (.env) - check it against the account, and a wrong one fails
docker compose exec -T -e CHECK_PASSWORD="$ROOT_PASSWORD" gitlab gitlab-rails runner 'exit(User.find_by_username("root").valid_password?(ENV.fetch("CHECK_PASSWORD")) ? 0 : 1)' \
  || fail "the root password from GITLAB_ROOT_PASSWORD does not match the root account"
if docker compose exec -T -e CHECK_PASSWORD="definitely-wrong-$token" gitlab gitlab-rails runner 'exit(User.find_by_username("root").valid_password?(ENV.fetch("CHECK_PASSWORD")) ? 0 : 1)'; then
  fail "a wrong password matched the root account"
fi
step "root password is the one from GITLAB_ROOT_PASSWORD"
auth="PRIVATE-TOKEN: $token"
resp=$(curl -sS -m 60 -w '\n%{http_code}' -H "$auth" -d name=smoke -d initialize_with_readme=true "$BASE/api/v4/projects") || fail "project request failed"
case ${resp##*$'\n'} in 2??) ;; *) fail "cannot create a project: $(printf '%s' "$resp" | head -c 400)" ;; esac
curl -fsS -m 60 -H "$auth" "$BASE/api/v4/projects?search=smoke" | grep -q '"name":"smoke"' || fail "project not found"
step "project created through the API"
repo_url=$(curl -fsS -m 60 -H "$auth" "$BASE/api/v4/projects?search=smoke" | py 'import json,sys; print(json.load(sys.stdin)[0]["http_url_to_repo"])') || fail "cannot read the clone URL"
case $repo_url in "$EXTERNAL"/*) step "clone URL uses the external URL ($repo_url)" ;; *) fail "clone URL $repo_url does not start with $EXTERNAL" ;; esac
echo "GitLab functional smoke test passed"
