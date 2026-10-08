# Valkey

[Valkey](https://valkey.io/), the Linux Foundation fork and drop-in replacement for Redis.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `valkey` | `valkey/valkey:latest` | 6379 | Data store |

## Quick start

```sh
mkdir -p valkey_data   # bind-mounted data directories must exist
docker compose up -d
```

```sh
docker compose exec valkey valkey-cli ping
```

## Notes

- No password is configured: do not expose port 6379 beyond localhost.
- Data is persisted in a volume mounted at `/data`.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
