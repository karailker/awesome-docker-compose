# Shared PostgreSQL / pgAdmin templates

`compose.yaml` holds two service templates used by the stacks that need a plain PostgreSQL database (both MLflow stacks, Superset, Metabase, the data platform and Langfuse):

| Template | What it defines |
|---|---|
| `postgres` | `postgres:17` (`POSTGRES_IMAGE` overrides it), the `postgres_data` volume at `/var/lib/postgresql/data`, `restart: unless-stopped` and a `pg_isready` healthcheck |
| `pgadmin` | `elestio/pgadmin:REL-9_18` (`PGADMIN_IMAGE`), login from `PGADMIN_EMAIL` / `PGADMIN_PASSWORD`, UI on `PGADMIN_PORT` (default 5433) |

A project extends them and adds what is its own:

```yaml
services:
  postgres:
    extends: {file: ../../shared/postgres/compose.yaml, service: postgres}
    container_name: my-postgres            # optional
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-mydb}
      POSTGRES_USER: ${POSTGRES_USER:-myuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-mypassword}
    volumes:
      - ./initdb:/docker-entrypoint-initdb.d:ro   # extra volumes are added to the template's
    networks: [my-network]
  pgadmin:
    extends: {file: ../../shared/postgres/compose.yaml, service: pgadmin}
    depends_on:
      postgres: {condition: service_healthy}
    networks: [my-network]
volumes:
  postgres_data:
    name: ${VOLUME_PREFIX:-my-project}_postgres_data
```

The healthcheck reads `POSTGRES_USER` / `POSTGRES_DB` from the container's own environment, so it needs no per-project copy. Same mechanism as [`shared/s3`](../s3/) (`extends` rather than `include:`, which cannot be customised per project).

Not shared on purpose: the standalone `base/postgres`, `base/pgvector`, `base/prefect`, `base/sonarqube` and `base/gitlab` projects (they are the reference setups or need their own settings, for example GitLab's `max_locks_per_transaction`), and Redis/Valkey - the stacks use different images and options (Valkey for Superset, `redis:7` for GitLab, a password for Langfuse, `redis:7.2` for Airflow), so a template would need as many overrides as it saves.
