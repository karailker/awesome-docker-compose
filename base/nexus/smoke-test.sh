#!/usr/bin/env bash
# Functional test: sign in with the generated admin password, create a hosted raw repository,
# upload a file and download it again.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="nexus smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
BASE=http://localhost:${NEXUS_PORT:-8081}

retry 300 "status endpoint answers" curl -fsS "$BASE/service/rest/v1/status/writable"
pw=$(docker compose exec -T nexus cat /nexus-data/admin.password 2>/dev/null | tr -d '\r\n')
[ -n "$pw" ] || fail "no generated admin password found"
auth="admin:$pw"
curl -fsS -m 60 -u "$auth" -H "$JSON" "$BASE/service/rest/v1/repositories/raw/hosted" \
  -d '{"name":"smoke","online":true,"storage":{"blobStoreName":"default","strictContentTypeValidation":false,"writePolicy":"ALLOW"}}' >/dev/null \
  || fail "cannot create the raw repository"
step "hosted raw repository created"
echo "hello from the smoke test" | curl -fsS -m 60 -u "$auth" -T - "$BASE/repository/smoke/hello.txt" || fail "upload failed"
[ "$(curl -fsS -m 60 "$BASE/repository/smoke/hello.txt" -u "$auth")" = "hello from the smoke test" ] || fail "downloaded content differs"
step "file uploaded and downloaded"
echo "Nexus functional smoke test passed"
