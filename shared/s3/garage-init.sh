#!/bin/sh
# One-shot Garage bootstrap through the admin API (the Garage image has no shell or CLI client):
# assign the single node to the cluster layout, import the access key given by S3_ACCESS_KEY /
# S3_SECRET_KEY and create the buckets listed in S3_BUCKETS with read/write/owner rights for it.
# Runs in curlimages/curl (POSIX sh, no jq). Safe to run again.
#
# Garage only accepts keys of the form "GK" + 24 hex characters (access) and 64 hex characters (secret).
set -eu

ADMIN="http://${GARAGE_HOST:-s3}:3903"
AUTH="Authorization: Bearer ${GARAGE_ADMIN_TOKEN:?GARAGE_ADMIN_TOKEN is required}"
AK="${S3_ACCESS_KEY:?S3_ACCESS_KEY is required}"
SK="${S3_SECRET_KEY:?S3_SECRET_KEY is required}"

case "$AK" in GK????????????????????????) ;; *) echo "S3_ACCESS_KEY must be GK + 24 hex characters for Garage" >&2; exit 1 ;; esac
[ "${#AK}" -eq 26 ] || { echo "S3_ACCESS_KEY must be GK + 24 hex characters for Garage" >&2; exit 1; }
[ "${#SK}" -eq 64 ] || { echo "S3_SECRET_KEY must be 64 hex characters for Garage" >&2; exit 1; }

api() {  # api <method> <path> [json body]   prints the body, returns non-zero on HTTP errors
  if [ $# -ge 3 ]; then
    curl -fsS -X "$1" -H "$AUTH" -H 'Content-Type: application/json' -d "$3" "$ADMIN$2"
  else
    curl -fsS -X "$1" -H "$AUTH" "$ADMIN$2"
  fi
}

echo "waiting for the Garage admin API"
i=0
until status=$(api GET /v2/GetClusterStatus 2>/dev/null); do
  i=$((i + 1)); [ "$i" -ge 60 ] && { echo "Garage admin API not reachable" >&2; exit 1; }
  sleep 2
done

if printf '%s' "$status" | grep -q '"layoutVersion": 0'; then
  node=$(printf '%s' "$status" | grep -o '"id": "[0-9a-f]*"' | head -1 | cut -d'"' -f4)
  echo "assigning node $node to the layout"
  api POST /v2/UpdateClusterLayout "{\"roles\":[{\"id\":\"$node\",\"zone\":\"dc1\",\"capacity\":${GARAGE_CAPACITY_BYTES:-1073741824},\"tags\":[]}]}" >/dev/null
  api POST /v2/ApplyClusterLayout '{"version":1}' >/dev/null
else
  echo "layout already applied"
fi

# the node needs a moment to pick up the layout
i=0
until curl -fsS "$ADMIN/health" >/dev/null 2>&1; do
  i=$((i + 1)); [ "$i" -ge 60 ] && { echo "Garage did not become healthy" >&2; exit 1; }
  sleep 2
done

api POST /v2/ImportKey "{\"name\":\"stack-key\",\"accessKeyId\":\"$AK\",\"secretAccessKey\":\"$SK\"}" >/dev/null 2>&1 \
  && echo "imported access key" || echo "access key already present"

for bucket in ${S3_BUCKETS:-}; do
  info=$(api POST /v2/CreateBucket "{\"globalAlias\":\"$bucket\"}" 2>/dev/null) || info=$(api GET "/v2/GetBucketInfo?globalAlias=$bucket")
  id=$(printf '%s' "$info" | grep -o '"id": "[0-9a-f]*"' | head -1 | cut -d'"' -f4)
  [ -n "$id" ] || { echo "cannot determine the id of bucket $bucket" >&2; exit 1; }
  api POST /v2/AllowBucketKey "{\"bucketId\":\"$id\",\"accessKeyId\":\"$AK\",\"permissions\":{\"read\":true,\"write\":true,\"owner\":true}}" >/dev/null
  echo "bucket $bucket ready"
done
echo "Garage is ready"
