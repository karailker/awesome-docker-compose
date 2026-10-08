# Milvus (standalone)

[Milvus](https://milvus.io/) vector database in standalone mode with etcd and an S3-compatible object store. Refactored from the official Milvus compose file.

> **Object storage:** MinIO Community Edition is no longer maintained. This setup uses the Chainguard MinIO image; see [base/minio](../minio/) for maintained alternatives (RustFS, SeaweedFS, Garage).

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `etcd` | `quay.io/coreos/etcd:v3.5.18` | internal | Metadata store |
| `minio` | `cgr.dev/chainguard/minio:latest` | 9000, 9001 | Object storage (API, console) |
| `standalone` | `milvusdb/milvus:v2.5.7` | 19530 (gRPC), 9091 (health/metrics) | Milvus server |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- Milvus endpoint: `localhost:19530`
- Health check: <http://localhost:9091/healthz>
- MinIO console: <http://localhost:9001>

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` | `minioadmin` / `minioadmin` | Object storage credentials (root user/password of MinIO) |
| `MINIO_ADDRESS` | `minio:9000` | Object storage address |
| `MINIO_REGION` | `us-east-1` | Region |
| `ETCD_ENDPOINTS` | `etcd:2379` | etcd address |
| `ETCD_AUTO_COMPACTION_MODE` / `_RETENTION` | `revision` / `1000` | etcd compaction |
| `ETCD_QUOTA_BACKEND_BYTES` | `4294967296` | etcd backend quota |
| `ETCD_SNAPSHOT_COUNT` | `50000` | etcd snapshot count |

## Notes

- The Chainguard MinIO image is distroless and non-root (uid `65532`): data directories under `./milvus_data` must be writable by it.
- The MinIO container has no healthcheck; `standalone` starts after it and restarts on failure until storage is reachable.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
