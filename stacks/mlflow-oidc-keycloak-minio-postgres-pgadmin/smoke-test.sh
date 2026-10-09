#!/usr/bin/env bash
# Functional test of the OIDC login, the way a browser does it, plus the artifact store:
#   1. MLflow answers, and the tracking API refuses anonymous requests
#   2. /login redirects to Keycloak, the demo user signs in on the Keycloak login form, Keycloak redirects
#      back to /callback, MLflow creates the session
#   3. the tracking API works with that session
#   4. the artifact bucket accepts a write, a read and a delete with the stack's S3 credentials
# Run by scripts/smoke.sh after the stack is up (working directory: this directory).
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="mlflow-oidc smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
BASE=http://localhost:5000
USER_NAME=admin@example.com   # demo user of keycloak/realm-mlflow.json
USER_PASSWORD="admin"
tmp=$(mktemp -d); jar=$tmp/cookies
# Keycloak is reached as keycloak:8081 (the issuer name MLflow uses), so map it to the published port
kc() { curl -sS -m 60 --resolve keycloak:8081:127.0.0.1 -b "$jar" -c "$jar" "$@"; }

mlflow_answers() { code=$(curl -s -o /dev/null -w '%{http_code}' "$BASE/"); [ "$code" != 000 ] && [ "$code" -lt 500 ]; }
retry 300 "MLflow answers" mlflow_answers
retry 120 "Keycloak realm is served" curl -fsS "http://localhost:8081/realms/mlflow/.well-known/openid-configuration"

search() { curl -s -o /dev/null -w '%{http_code}' -X POST -H "$JSON" -d '{"max_results":1}' "$@" "$BASE/api/2.0/mlflow/experiments/search"; }
anon=$(search)
case $anon in 200) fail "the tracking API answers anonymous requests (HTTP 200) - authentication is not enforced" ;; esac
step "anonymous tracking API request is refused (HTTP $anon)"

# --- 2. login through Keycloak
login_url=
for path in /login /oidc/login; do
  final=$(kc -L --max-redirs 10 -o "$tmp/login.html" -w '%{url_effective}' "$BASE$path") || true
  if grep -q 'kc-form-login' "$tmp/login.html" 2>/dev/null; then login_url=$final; break; fi
done
[ -n "$login_url" ] || fail "no Keycloak login form reached (last URL: ${final:-none}); first bytes: $(head -c 300 "$tmp/login.html" 2>/dev/null | tr '\n' ' ')"
step "MLflow redirected to the Keycloak login form"

action=$(python3 - "$tmp/login.html" <<'PY'
import html, re, sys
page = open(sys.argv[1], errors="ignore").read()
m = re.search(r'<form[^>]*id="kc-form-login"[^>]*action="([^"]+)"', page) or re.search(r'<form[^>]*action="([^"]+)"[^>]*id="kc-form-login"', page)
print(html.unescape(m.group(1)) if m else "")
PY
)
[ -n "$action" ] || fail "cannot find the action of the Keycloak login form"
result=$(kc -L --max-redirs 10 -o "$tmp/after.html" -w '%{url_effective} %{http_code}' \
  --data-urlencode "username=$USER_NAME" --data-urlencode "password=$USER_PASSWORD" --data-urlencode credentialId= "$action") \
  || fail "posting the Keycloak login form failed"
case $result in
  "$BASE"/*) step "Keycloak accepted the credentials and redirected back to MLflow ($result)" ;;
  *) fail "login did not end at MLflow: $result; page: $(sed -e 's/<[^>]*>//g' "$tmp/after.html" | tr -s ' \n' ' ' | head -c 300)" ;;
esac

# --- 3. the session works
code=$(search -b "$jar")
[ "$code" = 200 ] || fail "the tracking API answered HTTP $code with the OIDC session (expected 200)"
step "tracking API accepts the OIDC session (HTTP 200)"

# --- 4. artifact store
docker compose exec -T mlflow python - <<'PY' || fail "object store round trip failed"
import os, boto3
s3 = boto3.client("s3", endpoint_url=os.environ["MLFLOW_S3_ENDPOINT_URL"])
s3.put_object(Bucket="mlflow", Key="smoke/note.txt", Body=b"through the object store")
assert s3.get_object(Bucket="mlflow", Key="smoke/note.txt")["Body"].read() == b"through the object store"
s3.delete_object(Bucket="mlflow", Key="smoke/note.txt")
PY
step "bucket 'mlflow' accepts write/read/delete"
rm -rf "$tmp"
echo "MLflow-OIDC functional smoke test passed"
