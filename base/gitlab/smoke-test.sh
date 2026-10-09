#!/usr/bin/env bash
# Functional test: GitLab answers, root gets an API token and a project can be created through the API.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="gitlab smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
BASE=http://localhost:8090

# /-/readiness is limited to the monitoring IP allowlist (requests via the published port are rejected),
# so wait for the sign-in page instead (200, or a redirect to the configured external_url)
sign_in_page() { code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/users/sign_in"); [ "$code" = 200 ] || [ "$code" = 302 ]; }
retry 900 "GitLab answers (sign-in page)" sign_in_page
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
auth="PRIVATE-TOKEN: $token"
resp=$(curl -sS -m 60 -w '\n%{http_code}' -H "$auth" -d name=smoke -d initialize_with_readme=true "$BASE/api/v4/projects") || fail "project request failed"
case ${resp##*$'\n'} in 2??) ;; *) fail "cannot create a project: $(printf '%s' "$resp" | head -c 400)" ;; esac
curl -fsS -m 60 -H "$auth" "$BASE/api/v4/projects?search=smoke" | grep -q '"name":"smoke"' || fail "project not found"
step "project created through the API"
echo "GitLab functional smoke test passed"
