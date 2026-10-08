# MLflow + MinIO + PostgreSQL + pgAdmin

Self-hosted MLflow tracking server. Run metadata lives in PostgreSQL, artifacts live in MinIO (S3 API), and pgAdmin gives you a UI for the database.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `mlflow` | `ghcr.io/mlflow/mlflow` | 5000 | Tracking server / UI |
| `minio` | `cgr.dev/chainguard/minio` | 9000, 9001 | Artifact store (API, Console) |
| `createbuckets` | `cgr.dev/chainguard/minio-client:latest-dev` | - | One-shot job that creates the `mlflow` bucket (profile `init`) |
| `postgres` | `postgres` | internal | Backend store |
| `pgadmin` | `elestio/pgadmin` | 5433 | Database admin UI |

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose --profile init up createbuckets   # create the "mlflow" bucket (once)
```

- MLflow: <http://localhost:5000>
- MinIO Console: <http://localhost:9001> (`MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD`)
- pgAdmin: <http://localhost:5433> (`PGADMIN_EMAIL` / `PGADMIN_PASSWORD`)

Stop with `docker compose down`.

## Using it from Python

```python
import os, mlflow
os.environ["MLFLOW_S3_ENDPOINT_URL"] = "http://localhost:9000"
os.environ["AWS_ACCESS_KEY_ID"] = "minioadmin"
os.environ["AWS_SECRET_ACCESS_KEY"] = "minioadmin"

mlflow.set_tracking_uri("http://localhost:5000")
with mlflow.start_run():
    mlflow.log_param("hello", "world")
```

## Configuration

See `.env.example`: MinIO credentials, PostgreSQL credentials, pgAdmin login and `AWS_REGION`.
The Postgres credentials in the `mlflow` start command are currently the defaults (`myuser` / `mypassword` / `mydatabase`); update the `--backend-store-uri` if you change them.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `minio_data` | `mlflow-minio-postgres-pgadmin_minio_data` | `minio:/data`, `minio-init-perms:/data` |
| `postgres_data` | `mlflow-minio-postgres-pgadmin_postgres_data` | `postgres:/var/lib/postgresql/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `mlflow-minio-postgres-pgadmin`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p minio_data postgres_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Notes

- The `init` profile must be passed explicitly: `docker compose --profile init ...`.
- The MinIO image is distroless and runs as a non-root user (uid `65532`). The one-shot `minio-init-perms` service (busybox) fixes the ownership of the data volume before MinIO starts, so no manual `chown` is needed.
- Development defaults only; change all passwords before exposing the stack.
