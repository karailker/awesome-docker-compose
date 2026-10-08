# Apache Superset

[Apache Superset](https://superset.apache.org/) business-intelligence platform with PostgreSQL (metadata) and Valkey (cache), plus a ready-made sample database to build charts on.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `superset` | built from `Dockerfile` (`apache/superset:6.1.0`) | 8088 | Web UI and API |
| `superset-init` | same image | - | One-shot job: database migration, admin user, roles and permissions |
| `postgres` | `postgres:17` | internal | Superset metadata database and the sample `analytics` database |
| `redis` | `valkey/valkey:9.1.2` | internal | Cache (Valkey is Redis-compatible; the service keeps the name Superset docs use) |

The official Superset image has no PostgreSQL driver, so `Dockerfile` adds `psycopg2-binary`. The Superset version lives in that Dockerfile (`ARG SUPERSET_VERSION`), where Renovate updates it.

## Quick start

```sh
cp .env.example .env
docker compose up -d --build
```

- Superset: <http://localhost:8088> (`SUPERSET_ADMIN_USER` / `SUPERSET_ADMIN_PASSWORD`, default `admin` / `admin`)
- The first start takes a minute: `superset-init` migrates the database before the web server starts.

### Try it with the sample data

The Postgres container creates a small `analytics` database with an `orders` table on first start. In Superset: **Settings -> Database Connections -> + Database -> PostgreSQL**, host `postgres`, port `5432`, database `analytics`, user/password from `.env` (`superset` / `superset`). Then open **SQL Lab** and run `SELECT country, sum(amount) FROM orders GROUP BY country`.
(`smoke-test.sh` does exactly this through the API and is run by CI.)

## Configuration

Copy `.env.example` to `.env`. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `SUPERSET_SECRET_KEY` | `change-me-to-a-long-random-string` | Signs sessions and encrypts stored credentials - **change it** (`openssl rand -base64 42`) |
| `SUPERSET_ADMIN_USER` / `SUPERSET_ADMIN_PASSWORD` / `SUPERSET_ADMIN_EMAIL` | `admin` / `admin` / `admin@example.com` | Admin account created on first start |
| `SUPERSET_PORT` | `8088` | Host port |
| `SUPERSET_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | `superset` | Metadata database |
| `SUPERSET_IMAGE` | `awesome-compose/superset:local` | Name of the locally built image |

Further Superset settings go into `superset_config.py` (mounted read-only).

## Data and volumes

| Volume | Default name | Mounted at |
|---|---|---|
| `postgres_data` | `superset_postgres_data` | `postgres:/var/lib/postgresql/data` |
| `redis_data` | `superset_redis_data` | `redis:/data` |

- **Rename:** set `VOLUME_PREFIX` (volumes are named `<VOLUME_PREFIX>_<volume>`).
- **Host folders instead:** `mkdir -p postgres_data redis_data && docker compose -f compose.yaml -f compose.bind.yaml up -d` (`DATA_DIR` sets the parent directory).
- The sample database is only created when the Postgres volume is empty. `docker compose down -v` deletes everything.

## Notes

- Development defaults only: change the secret key and the passwords before exposing the stack. Superset refuses to start with its built-in placeholder key, which is why `SUPERSET_SECRET_KEY` is always set here.
- Talisman (HTTPS headers) is disabled for local plain-HTTP use; enable it behind a TLS proxy.
- Alternatives: [Metabase](../metabase/) is lighter and simpler for dashboards; Superset offers more chart types and SQL Lab.
