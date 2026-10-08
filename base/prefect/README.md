# Prefect

[Prefect](https://www.prefect.io/) 3 server with a worker and a PostgreSQL backend for workflow orchestration.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `prefect-server` | `prefecthq/prefect:3-latest` | 4200 | API and UI |
| `prefect-worker-1` | `prefecthq/prefect:3-latest` | - | Worker for the `default` work pool |
| `prefect_postgres` | `postgres:17` | internal | Database |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- UI: <http://localhost:4200>
- Point a client at it: `prefect config set PREFECT_API_URL=http://localhost:4200/api`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_DB` | `mydatabase` | Database (`.env.example` uses `mydb`) |
| `POSTGRES_USER` | `myuser` | Database user |
| `POSTGRES_PASSWORD` | `mypassword` | Database password |

## Notes

- The worker polls the `default` work pool; create it in the UI or with `prefect work-pool create default`.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
