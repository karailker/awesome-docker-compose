# Grafana with Prometheus

Grafana with a provisioned Prometheus data source and a sample dashboard.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `grafana` | `grafana/grafana:latest` | 3000 | Dashboards |
| `prometheus` | `prom/prometheus:latest` | 9090 | Metrics storage |

## Quick start

```sh
cp .env.example .env
mkdir -p grafana_data prometheus_data   # bind-mounted data directories must exist
docker compose up -d
```

- Grafana: <http://localhost:3000> (`GF_ADMIN_USER` / `GF_ADMIN_PASSWORD`)
- Prometheus: <http://localhost:9090>

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `GF_ADMIN_USER` | `admin` | Grafana admin user |
| `GF_ADMIN_PASSWORD` | `admin` | Grafana admin password |

## Notes

- Provisioning lives in `grafana/provisioning/` (data source and dashboards); scrape targets in `prometheus/prometheus.yml`.
- Sign-up is disabled.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
