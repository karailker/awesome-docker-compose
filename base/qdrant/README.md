# Qdrant

[Qdrant](https://qdrant.tech/) vector database for storing and searching high-dimensional vectors. Refactored from the official Qdrant compose example.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `qdrant` | `qdrant/qdrant:latest` | 6333 (REST), 6334 (gRPC) | Vector database |

## Quick start

```sh
mkdir -p qdrant_data   # bind-mounted data directories must exist
docker compose up -d
```

- REST API and dashboard: <http://localhost:6333/dashboard>
- gRPC: `localhost:6334`

## Notes

- Configuration is read from `config/production.yaml` (mounted read-only). To enable API-key authentication add `service.api_key` there.
- Data is stored in `./qdrant_data`.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
