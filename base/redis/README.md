# Redis with RedisInsight

Redis in-memory data store with an optional RedisInsight UI.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `redis` | `redis:latest` | 6379 | Data store |
| `redis-insight` | `redislabs/redisinsight` | 5540 | Web UI (profile `redis-insight`) |

## Quick start

```sh
mkdir -p redis_data redis_insight_data   # bind-mounted data directories must exist
docker compose up -d
docker compose --profile redis-insight up -d
```

- Redis: `redis-cli -h localhost -p 6379 ping`
- RedisInsight: <http://localhost:5540> (add a database with host `redis`, port `6379`)

## Notes

- No password is configured: do not expose port 6379 beyond localhost.
- The images use the `latest` tag; pin versions for reproducible setups. `redislabs/redisinsight` is the legacy repository name (`redis/redisinsight` is the current one).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
