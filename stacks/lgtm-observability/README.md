# LGTM observability stack (Loki, Grafana, Tempo, Prometheus + OpenTelemetry Collector)

Logs, metrics and traces in one place. Applications send OpenTelemetry (OTLP) data to a collector, which routes traces to **Tempo**, metrics to **Prometheus** and logs to **Loki**; **Grafana** is pre-provisioned with all three data sources, trace-to-log links and an overview dashboard.

## Services

| Service | Image | Port(s) | Purpose |
|---------|-------|---------|---------|
| `otel-collector` | `otel/opentelemetry-collector-contrib` | 4317 (OTLP gRPC), 4318 (OTLP HTTP) | Receives OTLP and fans it out |
| `tempo` | `grafana/tempo` | 3200 | Trace storage (single binary, local disk); also generates span metrics and the service graph |
| `loki` | `grafana/loki` | 3100 | Log storage (single binary, local disk) |
| `prometheus` | `prom/prometheus` | 9090 | Metrics (scrapes the stack, accepts OTLP metrics and Tempo's remote write), evaluates the alert rules |
| `alertmanager` | `prom/alertmanager` | 9093 | Receives, groups and routes the alerts |
| `grafana` | `grafana/grafana` | 3000 | UI with provisioned data sources and dashboard |
| `init-perms` | `busybox` | - | One-shot: makes the data volumes writable for the non-root images |
| `telemetrygen-*` | `telemetrygen` | - | Demo traffic generators (profile `demo`) |

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose --profile demo up -d      # optional: generate demo traces, metrics and logs
```

- Grafana: <http://localhost:3000> (`GF_ADMIN_USER` / `GF_ADMIN_PASSWORD`, default `admin` / `admin`). Open the **LGTM / LGTM overview** dashboard, or **Explore** with the Tempo, Loki or Prometheus data source.
- OTLP endpoints for your applications: `http://localhost:4318` (HTTP) and `localhost:4317` (gRPC). From other containers on the `lgtm_network` network use `otel-collector:4317` / `otel-collector:4318`.

## Sending data from your application

Any OpenTelemetry SDK works. For most languages the standard environment variables are enough:

```sh
export OTEL_SERVICE_NAME=my-app
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

Quick test without an SDK (sends one span; find it in Grafana under Explore > Tempo, query `{ resource.service.name = "curl-test" }`):

```sh
curl -X POST http://localhost:4318/v1/traces -H 'Content-Type: application/json' -d '{
  "resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"curl-test"}}]},
  "scopeSpans":[{"spans":[{"traceId":"5b8efff798038103d269b633813fc60c","spanId":"eee19b7ec3c1b174","name":"hello",
  "kind":1,"startTimeUnixNano":"1700000000000000000","endTimeUnixNano":"1700000001000000000"}]}]}]}'
```

Logs that carry a `trace_id` link to the trace (derived field in the Loki data source), and spans link to the logs of the same trace (`tracesToLogsV2` in the Tempo data source).

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|----------|---------|-------------|
| `GF_ADMIN_USER` / `GF_ADMIN_PASSWORD` | `admin` / `admin` | Grafana login (change it!) |
| `GRAFANA_PORT`, `PROMETHEUS_PORT`, `ALERTMANAGER_PORT`, `LOKI_PORT`, `TEMPO_PORT` | `3000`, `9090`, `9093`, `3100`, `3200` | Host ports |
| `OTLP_GRPC_PORT` / `OTLP_HTTP_PORT` | `4317` / `4318` | Host ports of the collector |
| `PROMETHEUS_RETENTION` | `7d` | Metrics retention |
| `DEMO_DURATION` | `30m` | How long the demo generators run |
| `*_IMAGE` | pinned versions | Override any image (`TEMPO_IMAGE`, `LOKI_IMAGE`, `OTELCOL_IMAGE`, `PROMETHEUS_IMAGE`, `GRAFANA_IMAGE`, `ALERTMANAGER_IMAGE`) |

Component configuration lives in `config/` (collector pipelines, Tempo, Loki, Prometheus scrape targets and alert rules, Alertmanager, Grafana provisioning and dashboards). Loki keeps logs for 7 days (`limits_config.retention_period`).

## Span metrics, service graph and alerting

- **Span metrics and service graph:** Tempo's metrics generator turns every ingested span into RED metrics (`traces_spanmetrics_calls_total`, `traces_spanmetrics_latency_*`, `traces_service_graph_request_total`) and remote-writes them to Prometheus (enabled with `--web.enable-remote-write-receiver`). In Grafana, the Tempo data source shows the **Service Graph** (Explore > Tempo > Service Graph) from these metrics.
- **Alert rules** are in `config/prometheus/alerts.yml`: `Watchdog` (always firing, proves the pipeline works), `TargetDown`, `HighSpanErrorRate` and `SlowSpans` (built on the span metrics). Edit the file and run `docker compose restart prometheus`.
- **Alertmanager** (<http://localhost:9093>) groups the alerts and routes them with `config/alertmanager/alertmanager.yml`. The default receiver has no integration, so alerts are only visible in the Alertmanager UI and in Grafana (the Alertmanager data source); add a webhook, e-mail or Slack receiver there to get notified.

## Testing

`smoke-test.sh` sends a trace, a metric and a log line through the collector and reads each one back from Tempo, Prometheus and Loki, checks that Tempo produced span metrics for the trace, that Prometheus loaded the alert rules and the always-firing Watchdog reached Alertmanager, then checks the four Grafana data sources and the dashboard. `scripts/smoke.sh stacks/lgtm-observability` runs it (so does CI, including the `demo` profile).

## Notes

- Development setup: single replicas, no authentication on Loki, Tempo, Prometheus and the collector, no TLS. Do not expose these ports; put a reverse proxy with authentication in front of Grafana before sharing it.
- The Tempo, Loki and collector images are distroless, so they have no container healthcheck. Dependents wait for them to start, and the functional test checks readiness.
- Port clashes: this stack uses the same ports as [Grafana with Prometheus](../../base/grafana/). Run one of them at a time or change the ports in `.env`.
- Tempo 3.x runs here in its single-binary mode with local storage.
- Needs roughly 2 GB of RAM.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `grafana_data` | `lgtm-observability_grafana_data` | `grafana:/var/lib/grafana`, `init-perms:/grafana` |
| `alertmanager_data` | `lgtm-observability_alertmanager_data` | `alertmanager:/alertmanager`, `init-perms:/alertmanager` |
| `loki_data` | `lgtm-observability_loki_data` | `init-perms:/loki`, `loki:/loki` |
| `prometheus_data` | `lgtm-observability_prometheus_data` | `init-perms:/prometheus`, `prometheus:/prometheus` |
| `tempo_data` | `lgtm-observability_tempo_data` | `init-perms:/tempo`, `tempo:/var/tempo` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `lgtm-observability`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p loki_data tempo_data prometheus_data grafana_data alertmanager_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose --profile demo down        # keep data
docker compose --profile demo down -v     # also remove the data volumes
```
