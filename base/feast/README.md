# Feast feature store

[Feast](https://feast.dev/) open-source feature store: online, offline and registry feature servers plus the UI, all backed by `feature_repo/`.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `online-feature-server` | `quay.io/feastdev/feature-server` | 6566 | Online serving |
| `offline-feature-server` | `quay.io/feastdev/feature-server` | 8815 | Offline (Arrow Flight) serving |
| `registry-feature-server` | `quay.io/feastdev/feature-server` | 6570, 6572 | Registry (gRPC and REST) |
| `feast-ui` | `quay.io/feastdev/feature-server` | 8888 | Web UI |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- UI: <http://localhost:8888>
- Online server: <http://localhost:6566>

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `FEAST_IMAGE` | `quay.io/feastdev/feature-server:0.66.0` | Image |
| `FEAST_REPO_PATH` | `./feature_repo` | Host path of the feature repository |
| `ONLINE_PORT` / `OFFLINE_PORT` | `6566` / `8815` | Server ports |
| `REGISTRY_PORT` / `REGISTRY_REST_PORT` | `6570` / `6572` | Registry ports |
| `FEAST_UI_PORT` | `8888` | UI port |
| `FEAST_LOG_LEVEL` | `INFO` | Log level |

## Notes

- Edit `feature_repo/feature_store.yaml` and add your feature definitions to the same folder, then run `feast apply` against it.
- The image is pinned to a release; bump `FEAST_IMAGE` to upgrade.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
