# InfluxDB with Telegraf

InfluxDB 2 time-series database with an optional Telegraf agent that collects host metrics.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `influxdb` | `influxdb:2.7-alpine` | 8086 | Time-series database and UI |
| `telegraf` | `telegraf:1.30-alpine` | - | Metrics agent (profile `telegraf`) |

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose --profile telegraf up -d    # add the Telegraf agent
```

- UI and API: <http://localhost:8086> (`INFLUXDB_USERNAME` / `INFLUXDB_PASSWORD`)
- API token: `INFLUXDB_ADMIN_TOKEN`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `INFLUXDB_USERNAME` / `INFLUXDB_PASSWORD` | `admin` / `adminpass` | Initial admin user |
| `INFLUXDB_ORG` | `my-org` | Organization |
| `INFLUXDB_BUCKET` | `default` | Initial bucket |
| `INFLUXDB_RETENTION` | `0` | Retention (0 = infinite) |
| `INFLUXDB_ADMIN_TOKEN` | `local-dev-token` | Admin API token (change it!) |
| `INFLUXDB_PORT` | `8086` | Host port |
| `INFLUXDB_IMAGE` / `TELEGRAF_IMAGE` | see `.env.example` | Image overrides |

## Notes

- Telegraf is configured in `telegraf/telegraf.conf` and writes to the bucket above.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
