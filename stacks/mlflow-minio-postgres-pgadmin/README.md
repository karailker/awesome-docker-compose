# MLflow + S3 object store (RustFS / SeaweedFS / Garage) + PostgreSQL + pgAdmin

Self-hosted MLflow tracking server. Run metadata lives in PostgreSQL, artifacts live in an S3-compatible object store (RustFS by default, SeaweedFS and Garage as variants), and pgAdmin gives you a UI for the database.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `mlflow` | `ghcr.io/mlflow/mlflow` | 5000 | Tracking server / UI |
| `s3` | `rustfs/rustfs` | 9000, 9001 | Artifact store (S3 API, console); see [variants](#object-store-variants) |
| `create-bucket` | `amazon/aws-cli` | - | One-shot job that creates the bucket(s) |
| `postgres` | `postgres` | internal | Backend store |
| `pgadmin` | `elestio/pgadmin` | 5433 | Database admin UI |

## Quick start

```sh
cp .env.example .env
docker compose up -d   # starts the store, creates the "mlflow" bucket, then MLflow
```

- MLflow: <http://localhost:5000>
- Store console (RustFS): <http://localhost:9001> (`S3_ACCESS_KEY` / `S3_SECRET_KEY`)
- pgAdmin: <http://localhost:5433> (`PGADMIN_EMAIL` / `PGADMIN_PASSWORD`)

Stop with `docker compose down`.

## Using it from Python

```python
import os, mlflow
os.environ["MLFLOW_S3_ENDPOINT_URL"] = "http://localhost:9000"
os.environ["AWS_ACCESS_KEY_ID"] = "GKdeadbeefdeadbeefdeadbeef"          # S3_ACCESS_KEY
os.environ["AWS_SECRET_ACCESS_KEY"] = "deadbeef" * 8                    # S3_SECRET_KEY

mlflow.set_tracking_uri("http://localhost:5000")
with mlflow.start_run():
    mlflow.log_param("hello", "world")
```

## Configuration

See `.env.example`: S3 credentials, PostgreSQL credentials, pgAdmin login and `AWS_REGION`.
The Postgres credentials in the `mlflow` start command are currently the defaults (`myuser` / `mypassword` / `mydatabase`); update the `--backend-store-uri` if you change them.

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
| `s3_data` | `mlflow-minio-postgres-pgadmin_s3_data` | `s3:/data` (Garage: `/var/lib/garage`) |
| `postgres_data` | `mlflow-minio-postgres-pgadmin_postgres_data` | `postgres:/var/lib/postgresql/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `mlflow-minio-postgres-pgadmin`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p s3_data postgres_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Notes

- The start command installs `psycopg2-binary` and `boto3` (neither is in the MLflow image; boto3 is required for the S3 artifact store) and uses the explicit `postgresql+psycopg2://` URI, because SQLAlchemy 2.1 would otherwise pick the psycopg 3 driver.
- `smoke-test.sh` (run by CI) logs a run with an artifact and reads it back through the store, for every variant.
- Development defaults only; change all passwords before exposing the stack.

### Migrating from the MinIO version of this project

Earlier versions ran MinIO (`minio` service). What changed: service `minio` -> `s3`; `MINIO_*` variables -> `S3_ACCESS_KEY` / `S3_SECRET_KEY`; volume `minio_data` -> `s3_data`; the `init` profile and `createbuckets` job are gone (bucket creation is automatic). Data in the old `minio_data` volume is not picked up - copy it over with `aws s3 sync` / `mc mirror` between the old and new store, or start fresh.
