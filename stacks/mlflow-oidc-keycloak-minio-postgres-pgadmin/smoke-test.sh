#!/usr/bin/env bash
# Functional test: the MLflow server (behind OIDC) is up and the artifact bucket accepts a write,
# a read and a delete with the stack's S3 credentials (RustFS / SeaweedFS / Garage).
# The tracking API itself requires an OIDC login, so the object store is tested directly.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
fail() { echo "::error::mlflow-oidc smoke test: $*"; exit 1; }

deadline=$((SECONDS + 300))
while :; do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:5000/)
  [ "$code" != 000 ] && [ "$code" -lt 500 ] && break
  [ $SECONDS -ge $deadline ] && fail "MLflow did not answer (last status $code)"
  sleep 5
done
echo "ok: MLflow answers"

docker compose exec -T mlflow python - <<'PY' || fail "object store round trip failed"
import os, boto3
s3 = boto3.client("s3", endpoint_url=os.environ["MLFLOW_S3_ENDPOINT_URL"])
s3.put_object(Bucket="mlflow", Key="smoke/note.txt", Body=b"through the object store")
assert s3.get_object(Bucket="mlflow", Key="smoke/note.txt")["Body"].read() == b"through the object store"
s3.delete_object(Bucket="mlflow", Key="smoke/note.txt")
PY
echo "ok: bucket 'mlflow' accepts write/read/delete"
