# PostgreSQL with pgAdmin

PostgreSQL 17 with an optional pgAdmin web UI.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `postgres` | `postgres:17` | internal 5432 | Database |
| `pgadmin` | `elestio/pgadmin` | 5433 | Web UI (profile `pgadmin`) |

## Quick start

```sh
cp .env.example .env
mkdir -p postgres_data   # bind-mounted data directories must exist
docker compose up -d                       # database only
docker compose --profile pgadmin up -d     # database + pgAdmin
```

- pgAdmin: <http://localhost:5433> (`PGADMIN_EMAIL` / `PGADMIN_PASSWORD`). Register a server with host `postgres`, port `5432` and your `POSTGRES_*` credentials.
- psql: `docker compose exec postgres psql -U myuser -d mydb`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_DB` | `mydatabase` | Database name (`.env.example` uses `mydb`) |
| `POSTGRES_USER` | `myuser` | Database user |
| `POSTGRES_PASSWORD` | `mypassword` | Database password (change it!) |
| `PGADMIN_EMAIL` | `admin@example.com` | pgAdmin login |
| `PGADMIN_PASSWORD` | `adminpassword` | pgAdmin password |

## Notes

- Port 5432 is **not** published to the host. Other containers reach it as `postgres:5432`; to connect from the host add `ports: ["5432:5432"]` to the service.
- Data is stored in the `postgres_data` volume (bind-mounted to `./postgres_data`).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
