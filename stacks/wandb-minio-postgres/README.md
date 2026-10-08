# Weights & Biases Local + S3 object store (RustFS / SeaweedFS / Garage) + MySQL

Self-hosted [W&B Local](https://docs.wandb.ai/guides/hosting) for experiment tracking, with an S3-compatible object store (RustFS by default, SeaweedFS and Garage as variants) for artifacts and MySQL as the metadata database.

> Status: work in progress (see the roadmap in the root README). W&B Local may require a license/login for full functionality.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `wandb` | `wandb/local` | 8088 | W&B UI/API |
| `s3` | `rustfs/rustfs` | 9000, 9001 | Object storage; see [variants](#object-store-variants) |
| `create-bucket` | `amazon/aws-cli` | - | One-shot job that creates the bucket(s) |
| `mysql` | `mysql:8.4` | 3306 | Metadata store |

## Quick start

```sh
cp .env.example .env
docker compose up -d   # starts the store, creates ${S3_BUCKET}, then W&B
docker compose up -d
```

- W&B: <http://localhost:8088>
- RustFS console: <http://localhost:9001>

Point the client at it:

```sh
wandb login --host http://localhost:8088
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `S3_ACCESS_KEY` / `S3_SECRET_KEY` | `GKdeadbeef…` / `deadbeef…` | Object store credentials |
| `S3_BUCKET` | `wandb-bucket` | Bucket used by W&B (created automatically) |
| `AWS_REGION` | `us-east-1` | S3 region |
| `MYSQL_DATABASE` / `MYSQL_USER` / `MYSQL_PASSWORD` / `MYSQL_ROOT_PASSWORD` | `wandb` / `wandbuser` / `wandbpass` / `rootpass` | MySQL settings |

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
| `s3_data` | `wandb-minio-postgres_s3_data` | `s3:/data` (Garage: `/var/lib/garage`) |
| `mysql_data` | `wandb-minio-postgres_mysql_data` | `mysql:/var/lib/mysql` |
| `wandb_data` | `wandb-minio-postgres_wandb_data` | `wandb:/vol` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `wandb-minio-postgres`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p wandb_data s3_data mysql_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Notes

- `wandb` starts after the bucket exists. `smoke-test.sh` (run by CI) checks the UI health endpoint and a write/read/delete in the bucket, for every variant.
- Development defaults only; change all passwords before exposing the stack.

### Migrating from the MinIO version of this project

Earlier versions ran MinIO (`minio` service). What changed: service `minio` -> `s3`; `MINIO_*` variables -> `S3_ACCESS_KEY` / `S3_SECRET_KEY`; `MINIO_BUCKET_NAME` -> `S3_BUCKET`; volume `minio_data` -> `s3_data`; the `init` profile and `createbuckets` job are gone (bucket creation is automatic). Data in the old `minio_data` volume is not picked up - copy it over with `aws s3 sync` / `mc mirror` between the old and new store, or start fresh.
