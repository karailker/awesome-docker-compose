#!/usr/bin/env bash
# Functional test of the RAG path, step by step:
#   Ollama has the models -> embeddings -> text generation -> Qdrant similarity search
#   -> Open WebUI sees the Ollama models -> a document uploaded to Open WebUI is embedded
#      and stored in Qdrant.
# Run by scripts/smoke.sh after the stack is up (working directory: this directory).
set -uo pipefail
cd "$(dirname "$0")" || exit 1
# shellcheck disable=SC1091
[ -f .env ] && set -a && . ./.env && set +a
OLLAMA=http://localhost:${OLLAMA_PORT:-11434}
QDRANT=http://localhost:${QDRANT_PORT:-6333}
WEBUI=http://localhost:${WEBUI_PORT:-3000}
CHAT=${CHAT_MODEL:-llama3.2:1b}
EMBED=${EMBED_MODEL:-nomic-embed-text}
JSON='Content-Type: application/json'
PGV=${SMOKE_VARIANT:-}   # "pgvector": Open WebUI stores its vectors in PostgreSQL instead of Qdrant
psql_() { docker compose exec -T pgvector psql -U "${POSTGRES_USER:-openwebui}" -d "${POSTGRES_DB:-openwebui}" -tA "$@"; }

fail() { echo "::error::rag smoke test: $*"; exit 1; }
retry() {
  local secs=$1 what=$2; shift 2
  local deadline=$((SECONDS + secs))
  until "$@" >/dev/null 2>&1; do
    [ $SECONDS -ge $deadline ] && fail "$what (timeout after ${secs}s)"
    sleep 5
  done
  echo "ok: $what"
}
py() { python3 -c "$@"; }

retry 120 "Ollama answers" curl -fsS "$OLLAMA/api/version"
if [ "$PGV" = pgvector ]; then retry 120 "pgvector is ready" psql_ -c "select 1"; else retry 120 "Qdrant is ready" curl -fsS "$QDRANT/readyz"; fi

has_models() {
  curl -fsS "$OLLAMA/api/tags" | py "
import json, sys
names = [m['name'] for m in json.load(sys.stdin)['models']]
want = sys.argv[1:]
sys.exit(0 if all(any(n == w or n.startswith(w + ':') for n in names) for w in want) else 1)" "$CHAT" "$EMBED"
}
retry 1200 "models $CHAT and $EMBED are downloaded" has_models

embed() {  # embed <json array of texts>  -> prints a JSON array of vectors
  curl -fsS -m 120 "$OLLAMA/api/embed" -H "$JSON" -d "{\"model\":\"$EMBED\",\"input\":$1}" | py 'import json,sys; print(json.dumps(json.load(sys.stdin)["embeddings"]))'
}
docs='["The capital of France is Paris.","Bananas are yellow and grow in warm climates."]'
vectors=$(embed "$docs") || fail "embedding request failed"
dim=$(printf '%s' "$vectors" | py 'import json,sys; print(len(json.load(sys.stdin)[0]))')
[ "${dim:-0}" -gt 0 ] || fail "empty embedding"
echo "ok: $EMBED returns $dim-dimensional embeddings"

reply=$(curl -fsS -m 300 "$OLLAMA/api/generate" -H "$JSON" -d "{\"model\":\"$CHAT\",\"prompt\":\"Say hello in one short sentence.\",\"stream\":false,\"options\":{\"num_predict\":24}}" \
  | py 'import json,sys; print(json.load(sys.stdin)["response"].strip())') || fail "text generation failed"
[ -n "$reply" ] || fail "empty reply from $CHAT"
echo "ok: $CHAT replies: $reply"

if [ "$PGV" = pgvector ]; then
  # pgvector: store both sentences, ask a question, the right sentence must come back first
  psql_ -c "create extension if not exists vector; drop table if exists smoke_rag; create table smoke_rag (id int primary key, txt text, v vector($dim))" >/dev/null || fail "cannot create the pgvector table"
  printf '%s' "$vectors" | py '
import json, sys
v = json.load(sys.stdin); t = json.loads(sys.argv[1])
for i, txt in enumerate(t):
    print("insert into smoke_rag values (%d, \x27%s\x27, \x27%s\x27);" % (i + 1, txt, json.dumps(v[i])))' "$docs" | psql_ >/dev/null || fail "cannot insert into pgvector"
  question=$(embed '["What is the capital of France?"]' | py 'import json,sys; print(json.dumps(json.load(sys.stdin)[0]))') || fail "embedding of the question failed"
  top=$(psql_ -c "select txt from smoke_rag order by v <=> '$question' limit 1") || fail "pgvector query failed"
  case "$top" in *Paris*) echo "ok: pgvector returns the matching sentence: $top" ;; *) fail "wrong top hit: $top" ;; esac
  psql_ -c "drop table smoke_rag" >/dev/null
else
  # Qdrant: store both sentences, ask a question, the right sentence must come back first
  coll=smoke_rag
  curl -fsS -X DELETE "$QDRANT/collections/$coll" >/dev/null 2>&1 || true
  curl -fsS -X PUT "$QDRANT/collections/$coll" -H "$JSON" -d "{\"vectors\":{\"size\":$dim,\"distance\":\"Cosine\"}}" >/dev/null || fail "cannot create Qdrant collection"
  printf '%s' "$vectors" | py '
import json, sys
v = json.load(sys.stdin); t = json.loads(sys.argv[1])
print(json.dumps({"points": [{"id": i + 1, "vector": v[i], "payload": {"text": t[i]}} for i in range(len(t))]}))' "$docs" \
    | curl -fsS -X PUT "$QDRANT/collections/$coll/points?wait=true" -H "$JSON" -d @- >/dev/null || fail "cannot upsert into Qdrant"
  question=$(embed '["What is the capital of France?"]' | py 'import json,sys; print(json.dumps(json.load(sys.stdin)[0]))') || fail "embedding of the question failed"
  top=$(curl -fsS -X POST "$QDRANT/collections/$coll/points/query" -H "$JSON" -d "{\"query\":$question,\"limit\":1,\"with_payload\":true}" \
    | py 'import json,sys; print(json.load(sys.stdin)["result"]["points"][0]["payload"]["text"])') || fail "Qdrant query failed"
  case "$top" in *Paris*) echo "ok: Qdrant returns the matching sentence: $top" ;; *) fail "wrong top hit: $top" ;; esac
  curl -fsS -X DELETE "$QDRANT/collections/$coll" >/dev/null
fi

# Open WebUI
retry 600 "Open WebUI is healthy" curl -fsS "$WEBUI/health"
email="smoke-$(date +%s)@example.com"; password="smoke-$(openssl rand -hex 6)"
token=$(curl -fsS -m 60 "$WEBUI/api/v1/auths/signup" -H "$JSON" -d "{\"name\":\"smoke\",\"email\":\"$email\",\"password\":\"$password\",\"profile_image_url\":\"\"}" \
  | py 'import json,sys; print(json.load(sys.stdin)["token"])') || fail "cannot create the first Open WebUI user"
echo "ok: Open WebUI sign-up works"
auth="Authorization: Bearer $token"
webui_sees_models() {
  curl -fsS -m 60 -H "$auth" "$WEBUI/ollama/api/tags" | py "
import json, sys
names = [m['name'] for m in json.load(sys.stdin)['models']]
sys.exit(0 if any(n == sys.argv[1] or n.startswith(sys.argv[1] + ':') for n in names) else 1)" "$CHAT"
}
retry 120 "Open WebUI lists the Ollama model $CHAT" webui_sees_models

count_webui_collections() {
  if [ "$PGV" = pgvector ]; then psql_ -c "select count(*) from document_chunk" 2>/dev/null || echo 0; return; fi
  curl -fsS "$QDRANT/collections" | py 'import json,sys; print(len([c for c in json.load(sys.stdin)["result"]["collections"] if c["name"].startswith("open-webui")]))'
}
before=$(count_webui_collections)
doc=$(mktemp); echo "The smoke test document says that the secret word is pineapple." > "$doc"
curl -fsS -m 300 -H "$auth" -F "file=@$doc;filename=smoke.txt;type=text/plain" "$WEBUI/api/v1/files/" >/dev/null || fail "document upload to Open WebUI failed"
rm -f "$doc"
qdrant_has_new_collection() { [ "$(count_webui_collections)" -gt "$before" ]; }
retry 300 "the uploaded document was embedded and stored in Qdrant" qdrant_has_new_collection
echo "RAG functional smoke test passed"
