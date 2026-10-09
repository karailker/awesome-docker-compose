# Metabase

[Metabase](https://www.metabase.com/) open-source BI tool with PostgreSQL as its application database, plus a ready-made sample database to ask questions about.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `metabase` | `metabase/metabase:v0.64.1.3` | 3000 | Web UI and API |
| `postgres` | `postgres:17` | internal | Metabase application database and the sample `analytics` database |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- Metabase: <http://localhost:3000> - the setup wizard asks for the admin account on first visit (the first start takes about a minute).

### Try it with the sample data

The Postgres container creates a small `analytics` database with an `orders` table on first start. In Metabase: **Admin -> Databases -> Add database -> PostgreSQL**, host `postgres`, port `5432`, database `analytics`, user/password from `.env` (`metabase` / `metabase`). Then **New -> SQL query** or browse the `orders` table.
(`smoke-test.sh` does this through the API and is run by CI.)

## Configuration

Copy `.env.example` to `.env`. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `METABASE_PORT` | `3000` | Host port |
| `METABASE_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | `metabase` | Application database |
| `METABASE_ENCRYPTION_KEY` | `change-me-...` | Encrypts database credentials stored by Metabase - **change it** (`openssl rand -base64 32`) and keep it, otherwise stored connections become unreadable |
| `METABASE_IMAGE` | `metabase/metabase:v0.64.1.3` | Other Metabase version |
| `METABASE_ADMIN_EMAIL` / `METABASE_ADMIN_PASSWORD` | see `.env.example` | Only used by `smoke-test.sh` |

## Data and volumes

| Volume | Default name | Mounted at |
|---|---|---|
| `postgres_data` | `metabase_postgres_data` | `postgres:/var/lib/postgresql/data` |

- **Rename:** set `VOLUME_PREFIX` (volumes are named `<VOLUME_PREFIX>_<volume>`).
- **Host folders instead:** `mkdir -p postgres_data && docker compose -f compose.yaml -f compose.bind.yaml up -d` (`DATA_DIR` sets the parent directory).
- The sample database is only created when the Postgres volume is empty. `docker compose down -v` deletes everything.

## Notes

- Metabase reports usage to its telemetry endpoint and checks for updates by default; disable it in **Admin -> Settings** (or set `MB_ANON_TRACKING_ENABLED=false`).
- Development defaults only: change the passwords and the encryption key before exposing the stack.
- Alternatives: [Superset](../superset/) offers more chart types and SQL Lab; Metabase is simpler for self-service questions.
