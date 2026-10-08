#!/usr/bin/env bash
# Functional test: W&B Local is healthy and its bucket on the S3 object store (RustFS / SeaweedFS /
# Garage) accepts a write and a read with the stack's credentials.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
fail() { echo "::error::wandb smoke test: $*"; exit 1; }

deadline=$((SECONDS + 300))
until curl -fsS -o /dev/null "http://localhost:8088/healthz" 2>/dev/null; do
  [ $SECONDS -ge $deadline ] && fail "W&B did not become healthy"
  sleep 5
done
echo "ok: W&B Local is healthy"

docker compose run --rm --no-deps --entrypoint /bin/sh create-bucket -c '
  set -e
  ep="--endpoint-url http://s3:9000"
  b=${S3_BUCKETS%% *}
  aws $ep s3api head-bucket --bucket "$b"
  echo "through the object store" > /tmp/note.txt
  aws $ep s3 cp /tmp/note.txt "s3://$b/smoke/note.txt"
  aws $ep s3 cp "s3://$b/smoke/note.txt" - | grep -q "through the object store"
  aws $ep s3 rm "s3://$b/smoke/note.txt"
' || fail "bucket check failed"
echo "ok: bucket accepts write/read/delete"
