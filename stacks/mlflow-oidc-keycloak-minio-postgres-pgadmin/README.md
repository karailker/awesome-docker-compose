# MLflow (OIDC) + Keycloak + S3 object store (RustFS / SeaweedFS / Garage) + PostgreSQL + pgAdmin

MLflow with single sign-on through Keycloak using the [`mlflow-oidc-auth`](https://github.com/mlflow-oidc/mlflow-oidc-auth) plugin. Artifacts are stored in an S3-compatible object store (RustFS by default, SeaweedFS and Garage as variants), metadata in PostgreSQL.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `mlflow` | `ghcr.io/mlflow/mlflow` | 5000 | Tracking server with OIDC auth |
| `keycloak` | `quay.io/keycloak/keycloak` | 8081 | Identity provider (realm `mlflow` auto-imported) |
| `s3` | `rustfs/rustfs` | 9000, 9001 | Artifact store; see [variants](#object-store-variants) |
| `create-bucket` | `amazon/aws-cli` | - | One-shot job that creates the bucket(s) |
| `postgres` | `postgres` | internal | Backend store |
| `pgadmin` | `elestio/pgadmin` | 5433 | Database admin UI |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

1. Open <http://localhost:5000> and choose **Login with Keycloak**.
2. Sign in with the demo user from `keycloak/realm-mlflow.json`: `admin@example.com` / `admin` (member of `mlflow-users`).
3. Keycloak admin console: <http://localhost:8081> (`admin` / `admin`).

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OIDC_CLIENT_SECRET` | `mlflowsecret` | Must match the `mlflow-client` secret in the realm file |
| `S3_ACCESS_KEY` / `S3_SECRET_KEY` | `GKdeadbeef…` / `deadbeef…` | Object store credentials |
| `POSTGRES_*` | `myuser` / `mypassword` / `mydatabase` | PostgreSQL credentials |
| `PGADMIN_EMAIL` / `PGADMIN_PASSWORD` | see `.env.example` | pgAdmin login |

The realm (`keycloak/realm-mlflow.json`) defines the `mlflow` realm, the `mlflow-client` client with redirect URI `http://localhost:5000/callback`, the `mlflow-users` group and a demo user.

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
| `keycloak_data` | `mlflow-oidc-keycloak-minio-postgres-pgadmin_keycloak_data` | `keycloak:/opt/keycloak/data` |
| `s3_data` | `mlflow-oidc-keycloak-minio-postgres-pgadmin_s3_data` | `s3:/data` (Garage: `/var/lib/garage`) |
| `postgres_data` | `mlflow-oidc-keycloak-minio-postgres-pgadmin_postgres_data` | `postgres:/var/lib/postgresql/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `mlflow-oidc-keycloak-minio-postgres-pgadmin`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p s3_data postgres_data keycloak_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Notes

- First start installs `mlflow-oidc-auth` with pip, so MLflow takes a minute to become available.
- `OAUTHLIB_INSECURE_TRANSPORT=1` and debug logging are for local development only.
- The start command installs `psycopg2-binary` and `boto3` (neither is in the MLflow image; boto3 is required for the S3 artifact store) and uses the explicit `postgresql+psycopg2://` URI (SQLAlchemy 2.1 would otherwise pick the psycopg 3 driver).
- `smoke-test.sh` (run by CI) checks that MLflow answers and that the `mlflow` bucket accepts a write, read and delete, for every variant.
- Replace all default passwords and secrets, and put the stack behind TLS, before any real use.

### Migrating from the MinIO version of this project

Earlier versions ran MinIO (`minio` service). What changed: service `minio` -> `s3`; `MINIO_*` variables -> `S3_ACCESS_KEY` / `S3_SECRET_KEY`; volume `minio_data` -> `s3_data`; the `init` profile and `createbuckets` job are gone (bucket creation is automatic). Data in the old `minio_data` volume is not picked up - copy it over with `aws s3 sync` / `mc mirror` between the old and new store, or start fresh.
