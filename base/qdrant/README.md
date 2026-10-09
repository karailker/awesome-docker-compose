# Qdrant

[Qdrant](https://qdrant.tech/) vector database for storing and searching high-dimensional vectors. Refactored from the official Qdrant compose example.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `qdrant` | `qdrant/qdrant:v1.19.2` | 6333 (REST), 6334 (gRPC) | Vector database |

## Quick start

```sh
docker compose up -d
```

- REST API and dashboard: <http://localhost:6333/dashboard>
- gRPC: `localhost:6334`

## Notes

- Configuration is read from `config/production.yaml` (mounted read-only). To enable API-key authentication add `service.api_key` there.

## Testing

`smoke-test.sh` (run by CI with `scripts/smoke.sh base/qdrant`) creates a collection, upserts points, runs a similarity search and a payload-filtered search.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|


- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `qdrant`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p qdrant_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
