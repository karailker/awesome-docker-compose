# CockroachDB

Single-node CockroachDB in insecure mode for development, with an optional job that creates a database and user.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `cockroach` | `cockroachdb/cockroach:v25.2.6` | 26257 (SQL), 26357 (gRPC), 8088 (Admin UI) | Database |
| `initdb` | `cockroachdb/cockroach:v25.2.6` | - | One-shot init job (profile `init`) |

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose --profile init up initdb     # creates the database and user once
```

- Admin UI: <http://localhost:8088>
- SQL shell: `docker compose exec cockroach cockroach sql --insecure`
- Connection string: `postgresql://app@localhost:26257/appdb?sslmode=disable` (no password in insecure mode)

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `COCKROACH_DATABASE` | `appdb` | Database created by the init job |
| `COCKROACH_USER` | `app` | User created by the init job |
| `COCKROACH_SQL_PORT` / `_HTTP_PORT` / `_GRPC_PORT` | `26257` / `8088` / `26357` | Host ports |
| `COCKROACH_IMAGE` | `cockroachdb/cockroach:v25.2.6` | Image override |

## Notes

- `--insecure` disables TLS and authentication, so users have no passwords: development only. The database is created on first start by the image (`COCKROACH_DATABASE`); the `init` profile additionally creates the user.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
