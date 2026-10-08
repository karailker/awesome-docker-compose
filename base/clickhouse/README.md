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

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `clickhouse_config` | `clickhouse_clickhouse_config` | `clickhouse:/etc/clickhouse-server` |
| `clickhouse_data` | `clickhouse_clickhouse_data` | `clickhouse:/var/lib/clickhouse` |
| `clickhouse_logs` | `clickhouse_clickhouse_logs` | `clickhouse:/var/log/clickhouse-server` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `clickhouse`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p clickhouse_data clickhouse_logs clickhouse_config
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
