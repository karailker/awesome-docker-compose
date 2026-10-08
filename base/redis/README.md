# Redis with RedisInsight

Redis in-memory data store with an optional RedisInsight UI.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `redis` | `redis:8.10.2` | 6379 | Data store |
| `redis-insight` | `redislabs/redisinsight` | 5540 | Web UI (profile `redis-insight`) |

## Quick start

```sh
docker compose up -d
docker compose --profile redis-insight up -d
```

- Redis: `redis-cli -h localhost -p 6379 ping`
- RedisInsight: <http://localhost:5540> (add a database with host `redis`, port `6379`)

## Notes

- No password is configured: do not expose port 6379 beyond localhost.
- Image versions are pinned. Redis 8 is licensed under the RSALv2/SSPLv1/AGPLv3 triple license; for a permissively licensed drop-in see [Valkey](../valkey/).

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `redis_data` | `redis_redis_data` | `redis:/data` |
| `redis_insight_data` | `redis_redis_insight_data` | `redis-insight:/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `redis`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p redis_data redis_insight_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
