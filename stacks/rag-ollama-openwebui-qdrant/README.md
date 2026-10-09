# Local RAG / LLM stack (Ollama + Open WebUI + Qdrant)

A private ChatGPT-style UI with document question answering ("chat with your files"), running entirely on your machine. **Ollama** runs the models, **Open WebUI** is the chat UI and RAG front end, **Qdrant** stores the document embeddings.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `ollama` | `ollama/ollama` | 11434 | Runs the chat and embedding models |
| `ollama-models` | `ollama/ollama` | - | One-shot job: downloads `CHAT_MODEL` and `EMBED_MODEL` into the volume |
| `qdrant` | `qdrant/qdrant` | 6333 | Vector database (REST API, dashboard at `/dashboard`) |
| `open-webui` | `ghcr.io/open-webui/open-webui` | 3000 | Chat UI, document upload, RAG |

All ports are published on `127.0.0.1` only (`BIND_ADDRESS`, `WEBUI_BIND_ADDRESS`): neither Ollama nor Qdrant has authentication.

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose logs -f ollama-models     # the first start downloads the models (about 1.6 GB)
```

1. Open <http://localhost:3000>. The **first account you create becomes the administrator**.
2. Pick the chat model and start chatting. Attach a document (paperclip) or create a Knowledge collection to ask questions about your files; the embeddings are computed by Ollama (`EMBED_MODEL`) and stored in Qdrant.
3. Qdrant dashboard: <http://localhost:6333/dashboard>. Open WebUI creates collections whose names start with `open-webui`.

Use the models directly:

```sh
docker compose exec ollama ollama run llama3.2:1b
curl http://localhost:11434/api/generate -d '{"model":"llama3.2:1b","prompt":"Hello","stream":false}'
```

## Vector database variants

Qdrant is the default. To store the vectors in PostgreSQL with the [pgvector](https://github.com/pgvector/pgvector) extension instead:

```sh
docker compose -f compose.yaml -f compose.pgvector.yaml up -d      # or COMPOSE_FILE=compose.yaml:compose.pgvector.yaml in .env
```

This adds a `pgvector` service (`pgvector/pgvector:pg17`, `POSTGRES_*` / `PGVECTOR_PORT`, volume `pgvector_data`), sets `VECTOR_DB=pgvector` for Open WebUI and moves Qdrant behind the `qdrant` profile so it does not start. Use one variant per `openwebui_data` volume: documents indexed with one variant are not visible with the other. `smoke-test.sh` runs against both (`SMOKE_VARIANT=pgvector`), checks the similarity search with SQL (`order by v <=> ...`) and that an uploaded document lands in the `document_chunk` table.

## Choosing models

The defaults are small so that they run on a CPU-only laptop. Change them in `.env` and run `docker compose up -d` again (the job pulls what is missing). Browse <https://ollama.com/library> for models; bigger ones answer better but need more RAM:

| Model | Download | Notes |
|-------|----------|-------|
| `llama3.2:1b` (default) | about 1.3 GB | fast on CPU, modest quality |
| `llama3.2:3b` | about 2 GB | better answers, still usable on CPU |
| `nomic-embed-text` (default embeddings) | about 270 MB | good general-purpose embedding model |

If you change `EMBED_MODEL` after documents were indexed, re-index them: the vector size changes.

## GPU

On a host with an NVIDIA GPU and the NVIDIA Container Toolkit:

```sh
docker compose -f compose.yaml -f compose.gpu.yaml up -d
```

This override is **not tested in CI** (hosted runners have no GPU); it only reserves the GPU for the Ollama container.

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `CHAT_MODEL` | `llama3.2:1b` | Default chat model |
| `EMBED_MODEL` | `nomic-embed-text` | Embedding model used for RAG |
| `WEBUI_SECRET_KEY` | `dev-secret-change-me` | Signs Open WebUI sessions: change it |
| `ENABLE_SIGNUP` | `true` | Allow new users to register; set to `false` after creating your account |
| `BIND_ADDRESS` / `WEBUI_BIND_ADDRESS` | `127.0.0.1` | Interface for Ollama/Qdrant and for the UI; use `0.0.0.0` to expose them |
| `WEBUI_PORT`, `OLLAMA_PORT`, `QDRANT_PORT` | `3000`, `11434`, `6333` | Host ports |
| `OLLAMA_IMAGE`, `QDRANT_IMAGE`, `OPEN_WEBUI_IMAGE`, `PGVECTOR_IMAGE` | pinned versions | Override the images |

## Testing

`smoke-test.sh` exercises the whole RAG path: the models are downloaded, Ollama returns embeddings and generates text, Qdrant returns the matching sentence for a question, Open WebUI lists the Ollama models, and a document uploaded to Open WebUI ends up as a new collection in Qdrant. Run it with (add `SMOKE_VARIANT=pgvector` for the pgvector variant) `scripts/smoke.sh stacks/rag-ollama-openwebui-qdrant 900` (needs internet access to download the models; it is part of the weekly heavy workflow).

## Notes

- Development setup: no TLS, Ollama and Qdrant without authentication. Put a reverse proxy with TLS in front of Open WebUI before exposing it, and set `ENABLE_SIGNUP=false` once your accounts exist.
- The Open WebUI image is large (several GB) and the first start takes a minute or two.
- Models run on the CPU unless you use the GPU override, so replies from a 1B model take a few seconds.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `ollama_data` | `rag-ollama-openwebui-qdrant_ollama_data` | `ollama:/root/.ollama` |
| `openwebui_data` | `rag-ollama-openwebui-qdrant_openwebui_data` | `open-webui:/app/backend/data` |
| `qdrant_data` | `rag-ollama-openwebui-qdrant_qdrant_data` | `qdrant:/qdrant/storage` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `rag-ollama-openwebui-qdrant`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p ollama_data qdrant_data openwebui_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep models, documents and accounts
docker compose down -v     # also remove the volumes
```
