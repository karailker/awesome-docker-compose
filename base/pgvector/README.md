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
mkdir -p postgres_data   # bind-mounted data directories must exist
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

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
