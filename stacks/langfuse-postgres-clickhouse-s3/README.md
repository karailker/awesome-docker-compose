# Langfuse (LLM observability)

Self-hosted [Langfuse](https://langfuse.com/) v4: traces, prompts and evaluations for LLM applications. It needs five backing services, all included: PostgreSQL (metadata), ClickHouse (traces and observations), Redis (queue/cache) and an S3-compatible object store (event and media blobs; RustFS by default, SeaweedFS and Garage as variants - the same pattern as the MLflow and W&B stacks).

## Services

| Service | Image | Port | Purpose |
|---|---|---|---|
| `langfuse-web` | `langfuse/langfuse:4.55.0` | 3000 | UI and public API |
| `langfuse-worker` | `langfuse/langfuse-worker:4.55.0` | internal | Processes the ingestion queue, writes to ClickHouse |
| `postgres` | `postgres:17` | internal | Metadata |
| `clickhouse` | `clickhouse/clickhouse-server:25.12.11` | internal | Analytics store |
| `redis` | `redis:8.10.2` | internal | Queue and cache |
| `s3` | `rustfs/rustfs` | 9000, 9001 | Object store; see [variants](#object-store-variants) |
| `create-bucket` | `amazon/aws-cli` | - | One-shot job that creates the bucket |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- Langfuse: <http://localhost:3000> - sign in with `LANGFUSE_INIT_USER_EMAIL` / `LANGFUSE_INIT_USER_PASSWORD` (default `admin@example.com` / `change-me-password`). Organisation `Demo`, project `Demo project` and its API keys (`pk-lf-demo` / `sk-lf-demo`) are created on first start (headless initialisation).
- The first start takes a minute or two (database and ClickHouse migrations).

### Send a trace

```python
import os
os.environ.update(LANGFUSE_HOST="http://localhost:3000", LANGFUSE_PUBLIC_KEY="pk-lf-demo", LANGFUSE_SECRET_KEY="sk-lf-demo")
from langfuse import get_client            # v3+ SDK, built on OpenTelemetry
lf = get_client()
with lf.start_as_current_observation(name="hello", as_type="span", input="ping") as span:
    span.update(output="pong")
lf.flush()
```

Langfuse v4 receives traces as OpenTelemetry spans (the legacy `trace-create` events of `/api/public/ingestion` are rejected in the default `events_only` mode). Any OTLP exporter works; endpoint `http://localhost:3000/api/public/otel`, header `Authorization: Basic <base64 public:secret>` and `x-langfuse-ingestion-version: 4`. `smoke-test.sh` (run by CI) posts one span as OTLP/JSON to `/api/public/otel/v1/traces` and reads it back.

Use it with the [RAG stack](../rag-ollama-openwebui-qdrant/): point your application's Langfuse SDK (or an OpenTelemetry exporter) at `http://localhost:3000`.

## Object store variants

The S3 service is always called `s3` and listens on port 9000. RustFS is the default; switch with an override file:

| Variant | Command |
|---|---|
| **RustFS** (default) | `docker compose up -d` |
| **SeaweedFS** | `docker compose -f compose.yaml -f compose.seaweedfs.yaml up -d` |
| **Garage** | `docker compose -f compose.yaml -f compose.garage.yaml up -d` (the `garage-init` job bootstraps layout, key and bucket) |

Pick one variant per data volume. Credentials are `S3_ACCESS_KEY` / `S3_SECRET_KEY` (Garage-compatible format by default). Details: [`shared/s3/README.md`](../../shared/s3/README.md).

## Configuration

Copy `.env.example` to `.env`; every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `NEXTAUTH_SECRET`, `LANGFUSE_SALT` | placeholders | **Change both** for anything real |
| `LANGFUSE_ENCRYPTION_KEY` | 64 zeros | Encrypts stored LLM API keys - `openssl rand -hex 32` |
| `NEXTAUTH_URL` | `http://localhost:3000` | Public URL of the UI |
| `LANGFUSE_INIT_*`, `LANGFUSE_PUBLIC_KEY`, `LANGFUSE_SECRET_KEY` | demo values | Headless initial user, organisation, project and API keys |
| `POSTGRES_*`, `CLICKHOUSE_*`, `REDIS_AUTH` | see `.env.example` | Backing service credentials |
| `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_BUCKET` | see `.env.example` | Object store |
| `LANGFUSE_WEB_IMAGE`, `LANGFUSE_WORKER_IMAGE`, `CLICKHOUSE_IMAGE` | see `compose.yaml` | Other versions (keep web and worker on the same version) |

## Data and volumes

| Volume | Default name | Mounted at |
|---|---|---|
| `postgres_data` | `langfuse-postgres-clickhouse-s3_postgres_data` | `postgres:/var/lib/postgresql/data` |
| `clickhouse_data`, `clickhouse_logs` | `..._clickhouse_data`, `..._clickhouse_logs` | `clickhouse:/var/lib/clickhouse`, `/var/log/clickhouse-server` |
| `redis_data` | `..._redis_data` | `redis:/data` |
| `s3_data` | `..._s3_data` | `s3:/data` (Garage: `/var/lib/garage`) |

- **Rename:** set `VOLUME_PREFIX` (volumes are named `<VOLUME_PREFIX>_<volume>`).
- **Host folders instead:** `mkdir -p postgres_data clickhouse_data clickhouse_logs redis_data s3_data && docker compose -f compose.yaml -f compose.bind.yaml up -d` (`DATA_DIR` sets the parent directory). The ClickHouse folders must be writable for uid 101.
- `docker compose down -v` deletes all data.

## Notes

- Development defaults only. Change all secrets before exposing the stack. Telemetry to Langfuse is disabled (`LANGFUSE_TELEMETRY_ENABLED`).
- Media uploads use presigned URLs to `http://localhost:9000`; set `LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT` when Langfuse is reached under another host name.
- Needs about 3 GB of RAM.
