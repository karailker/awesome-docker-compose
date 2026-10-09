#!/usr/bin/env bash
# Functional test: authenticate, insert documents, query and aggregate them, and check that anonymous access is refused.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="mongodb smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
U=${MONGO_INITDB_ROOT_USERNAME:-root}; P=${MONGO_INITDB_ROOT_PASSWORD:-example}
mongo() { docker compose exec -T mongo mongosh --quiet "$@"; }
authed() { mongo -u "$U" -p "$P" --authenticationDatabase admin "$@"; }

retry 120 "MongoDB accepts the root user" authed --eval 'db.runCommand({ping:1}).ok'
# shellcheck disable=SC2016
out=$(authed smoke --eval '
  db.items.drop();
  db.items.insertMany([{k:"a",v:10},{k:"a",v:5},{k:"b",v:7}]);
  const r = db.items.aggregate([{$group:{_id:"$k",total:{$sum:"$v"}}},{$sort:{_id:1}}]).toArray();
  print(r.map(x => x._id + "=" + x.total).join(","));
  db.items.drop();') || fail "insert / aggregate failed"
[ "$out" = "a=15,b=7" ] || fail "aggregation returned '$out' instead of 'a=15,b=7'"
step "documents inserted and aggregated ($out)"
# --auth is on: an unauthenticated client must not be able to read
if mongo smoke --eval 'db.items.countDocuments({})' >/dev/null 2>&1; then
  fail "an unauthenticated client could query the database"
fi
step "unauthenticated access is refused"
echo "MongoDB functional smoke test passed"
