# PostgreSQL + pgvector with pgAdmin

PostgreSQL 17 with the [pgvector](https://github.com/pgvector/pgvector) extension for vector similarity search, plus an optional pgAdmin UI.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `postgres-pgvector` | `pgvector/pgvector:pg17` | 5432 | Database with pgvector |
| `pgadmin` | `elestio/pgadmin` | 5433 | Web UI (profile `pgadmin`) |

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose --profile pgadmin up -d     # optional UI
```

- Database: `localhost:5432`
- pgAdmin: <http://localhost:5433> (register a server with host `postgres-pgvector`)

## Try it

```sql
CREATE EXTENSION vector;
CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));
INSERT INTO items (embedding) VALUES ('[1,2,3]'), ('[4,5,6]');
SELECT * FROM items ORDER BY embedding <=> '[3,1,2]' LIMIT 5;
```

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_DB` | `mydatabase` | Database name (`.env.example` uses `mydb`) |
| `POSTGRES_USER` | `myuser` | Database user |
| `POSTGRES_PASSWORD` | `mypassword` | Database password |
| `PGADMIN_EMAIL` | `admin@example.com` | pgAdmin login |
| `PGADMIN_PASSWORD` | `adminpassword` | pgAdmin password |

## Notes

- Run `CREATE EXTENSION vector;` once per database.

## Testing

`smoke-test.sh` (run by CI with `scripts/smoke.sh base/pgvector`) enables the `vector` extension, stores embeddings with an HNSW index and checks the nearest-neighbour query.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `postgres_data` | `pgvector_postgres_data` | `postgres-pgvector:/var/lib/postgresql/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `pgvector`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p postgres_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
