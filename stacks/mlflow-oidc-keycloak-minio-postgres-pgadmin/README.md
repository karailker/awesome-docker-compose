# MLflow (OIDC) + Keycloak + MinIO + PostgreSQL + pgAdmin

MLflow with single sign-on through Keycloak using the [`mlflow-oidc-auth`](https://github.com/mlflow-oidc/mlflow-oidc-auth) plugin. Artifacts are stored in MinIO, metadata in PostgreSQL.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `mlflow` | `ghcr.io/mlflow/mlflow` | 5000 | Tracking server with OIDC auth |
| `keycloak` | `quay.io/keycloak/keycloak` | 8081 | Identity provider (realm `mlflow` auto-imported) |
| `minio` | `cgr.dev/chainguard/minio` | 9000, 9001 | Artifact store |
| `createbuckets` | `cgr.dev/chainguard/minio-client:latest-dev` | - | Creates the `mlflow` bucket (profile `init`) |
| `postgres` | `postgres` | internal | Backend store |
| `pgadmin` | `elestio/pgadmin` | 5433 | Database admin UI |

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose --profile init up createbuckets   # once
```

1. Open <http://localhost:5000> and choose **Login with Keycloak**.
2. Sign in with the demo user from `keycloak/realm-mlflow.json`: `admin@example.com` / `admin` (member of `mlflow-users`).
3. Keycloak admin console: <http://localhost:8081> (`admin` / `admin`).

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OIDC_CLIENT_SECRET` | `mlflowsecret` | Must match the `mlflow-client` secret in the realm file |
| `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` | `minioadmin` | MinIO credentials |
| `POSTGRES_*` | `myuser` / `mypassword` / `mydatabase` | PostgreSQL credentials |
| `PGADMIN_EMAIL` / `PGADMIN_PASSWORD` | see `.env.example` | pgAdmin login |

The realm (`keycloak/realm-mlflow.json`) defines the `mlflow` realm, the `mlflow-client` client with redirect URI `http://localhost:5000/callback`, the `mlflow-users` group and a demo user.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `keycloak_data` | `mlflow-oidc-keycloak-minio-postgres-pgadmin_keycloak_data` | `keycloak:/opt/keycloak/data` |
| `minio_data` | `mlflow-oidc-keycloak-minio-postgres-pgadmin_minio_data` | `minio:/data`, `minio-init-perms:/data` |
| `postgres_data` | `mlflow-oidc-keycloak-minio-postgres-pgadmin_postgres_data` | `postgres:/var/lib/postgresql/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `mlflow-oidc-keycloak-minio-postgres-pgadmin`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p minio_data postgres_data keycloak_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Notes

- First start installs `mlflow-oidc-auth` with pip, so MLflow takes a minute to become available.
- `OAUTHLIB_INSECURE_TRANSPORT=1` and debug logging are for local development only.
- The MinIO image is distroless and runs as a non-root user (uid `65532`). The one-shot `minio-init-perms` service (busybox) fixes the ownership of the data volume before MinIO starts, so no manual `chown` is needed.
- Replace all default passwords and secrets, and put the stack behind TLS, before any real use.
