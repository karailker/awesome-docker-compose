#!/usr/bin/env bash
# Functional test: enable the vector extension, store embeddings and find the nearest neighbour with an HNSW index.
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
cd "$here" || exit 1
export NAME="pgvector smoke test"
# shellcheck disable=SC1091
. "$here/../../scripts/smoke-lib.sh"
load_env
U=${POSTGRES_USER:-myuser}; D=${POSTGRES_DB:-mydatabase}
sql() { docker compose exec -T postgres-pgvector psql -v ON_ERROR_STOP=1 -U "$U" -d "$D" -tA "$@"; }

retry 120 "PostgreSQL accepts connections" sql -c 'select 1'
sql -c "create extension if not exists vector; drop table if exists smoke_items;
  create table smoke_items (id int primary key, label text, embedding vector(3));
  insert into smoke_items values (1,'x','[1,0,0]'), (2,'y','[0,1,0]'), (3,'z','[0,0,1]');
  create index on smoke_items using hnsw (embedding vector_cosine_ops)" >/dev/null || fail "cannot create the vector table and index"
nearest=$(sql -c "select label from smoke_items order by embedding <=> '[0.1,0.9,0]' limit 1") || fail "nearest-neighbour query failed"
[ "$nearest" = y ] || fail "nearest neighbour is '$nearest' instead of 'y'"
step "extension works: the nearest neighbour of [0.1,0.9,0] is '$nearest'"
sql -c 'drop table smoke_items' >/dev/null
echo "pgvector functional smoke test passed"
