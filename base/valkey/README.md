# Valkey

[Valkey](https://valkey.io/), the Linux Foundation fork and drop-in replacement for Redis.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `valkey` | `valkey/valkey:9.1.2` | 6379 | Data store |

## Quick start

```sh
docker compose up -d
```

```sh
docker compose exec valkey valkey-cli ping
```

## Notes

- No password is configured: do not expose port 6379 beyond localhost.
- Data is persisted in a volume mounted at `/data`.

## Testing

`smoke-test.sh` (run by CI with `scripts/smoke.sh base/valkey`) runs string, counter, list and key-expiry commands through `valkey-cli`.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `valkey_data` | `valkey_valkey_data` | `valkey:/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `valkey`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p valkey_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
