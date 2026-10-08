# ClickHouse with Tabix

ClickHouse columnar analytics database with the Tabix web SQL client.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `clickhouse` | `clickhouse/clickhouse-server:24.8-alpine` | 8123 (HTTP), 9000 (native), 9009 (interserver) | Database |
| `tabix` | `spoonest/clickhouse-tabix-web-client` | 8124 | Web query UI |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- HTTP interface: <http://localhost:8123/ping>
- Tabix: <http://localhost:8124> (host `http://localhost:8123`, user `CLICKHOUSE_USER`)
- CLI: `docker compose exec clickhouse clickhouse-client -u chadmin --password chpass`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `CLICKHOUSE_USER` | `chadmin` | Admin user (replaces `default`) |
| `CLICKHOUSE_PASSWORD` | `chpass` | Admin password |
| `CLICKHOUSE_DB` | `default` | Initial database |
| `CLICKHOUSE_HTTP_PORT` / `_NATIVE_PORT` / `_INTERSERVER_PORT` | `8123` / `9000` / `9009` | Host ports |
| `TABIX_PORT` | `8124` | Tabix host port |
| `CLICKHOUSE_IMAGE` / `TABIX_IMAGE` | see `.env.example` | Image overrides |

## Notes

- Port 9000 (native protocol) conflicts with MinIO/RustFS if you run them at the same time.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
