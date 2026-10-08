# Milvus (standalone)

[Milvus](https://milvus.io/) vector database in standalone mode with etcd and an S3-compatible object store. Refactored from the official Milvus compose file.

> **Object storage:** MinIO Community Edition is no longer maintained, so Milvus runs on RustFS by default, with SeaweedFS and Garage as [variants](#object-store-variants). Milvus itself still calls the setting "MinIO" - any S3-compatible store works.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `etcd` | `quay.io/coreos/etcd:v3.5.18` | internal | Metadata store |
| `s3` | `rustfs/rustfs` | 9000, 9001 | Object storage (API, console) |
| `create-bucket` | `amazon/aws-cli` | - | One-shot job that creates the bucket(s) |
| `standalone` | `milvusdb/milvus:v2.5.7` | 19530 (gRPC), 9091 (health/metrics) | Milvus server |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- Milvus endpoint: `localhost:19530`
- Health check: <http://localhost:9091/healthz>
- RustFS console: <http://localhost:9001>

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `S3_ACCESS_KEY` / `S3_SECRET_KEY` | `GKdeadbeef…` / `deadbeef…` | Object storage credentials |
| `S3_BUCKET` | `a-bucket` | Bucket used by Milvus (created automatically) |
| `S3_ADDRESS` | `s3:9000` | Object storage address |
| `AWS_REGION` | `us-east-1` | Region |
| `ETCD_ENDPOINTS` | `etcd:2379` | etcd address |
| `ETCD_AUTO_COMPACTION_MODE` / `_RETENTION` | `revision` / `1000` | etcd compaction |
| `ETCD_QUOTA_BACKEND_BYTES` | `4294967296` | etcd backend quota |
| `ETCD_SNAPSHOT_COUNT` | `50000` | etcd snapshot count |

## Notes


## Object store variants

The S3 service is always called `s3` and always listens on port 9000 (inside the network and on the host), so the apps do not care which store runs underneath. RustFS is the default; switch with an override file:

| Variant | Command | Notes |
|---|---|---|
| **RustFS** (default) | `docker compose up -d` | Apache-2.0, closest MinIO replacement, console on <http://localhost:9001> |
| **SeaweedFS** | `docker compose -f compose.yaml -f compose.seaweedfs.yaml up -d` | Master UI on 9333, filer UI on 8888 |
| **Garage** | `docker compose -f compose.yaml -f compose.garage.yaml up -d` | Lightweight; the `garage-init` job assigns the cluster layout, imports the key and creates the bucket(s). Admin API on 3903 |

Set `COMPOSE_FILE=compose.yaml:compose.garage.yaml` in `.env` to make a variant permanent. Pick **one** variant per data volume - switching variants starts with an empty store (`docker compose down -v` first).

- Credentials: `S3_ACCESS_KEY` / `S3_SECRET_KEY`. The defaults look like `GK` + 24 hex characters and 64 hex characters because Garage accepts nothing else; the other stores accept any value.
- Bucket creation: the `create-bucket` job (AWS CLI) runs automatically and the apps wait for it. Buckets come from `S3_BUCKETS` (space separated).
- Images: `RUSTFS_IMAGE`, `SEAWEEDFS_IMAGE`, `GARAGE_IMAGE` select other versions (Renovate keeps the defaults current).


## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `etcd_data` | `milvus_etcd_data` | `etcd:/etcd` |
| `milvus_data` | `milvus_milvus_data` | `standalone:/var/lib/milvus` |
| `s3_data` | `milvus_s3_data` | `s3:/data` (Garage: `/var/lib/garage`) |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `milvus`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p milvus_data/etcd milvus_data/s3 milvus_data/milvus
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```

### Migrating from the MinIO version of this project

Earlier versions ran MinIO (`minio` service). What changed: service `minio` -> `s3`; `MINIO_*` variables -> `S3_ACCESS_KEY` / `S3_SECRET_KEY`; volume `minio_data` -> `s3_data`; the `init` profile and `createbuckets` job are gone (bucket creation is automatic). Data in the old `minio_data` volume is not picked up - copy it over with `aws s3 sync` / `mc mirror` between the old and new store, or start fresh.
