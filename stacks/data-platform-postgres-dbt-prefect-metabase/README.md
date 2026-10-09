# Data platform: PostgreSQL + dbt + Prefect + Metabase

A small, complete data platform on one machine: **PostgreSQL** is the warehouse, **dbt** transforms the data, **Prefect** schedules the dbt run, and **Metabase** lets you explore the result. It is built from the same pieces as [`base/postgres`](../../base/postgres/), [`base/prefect`](../../base/prefect/) and [`base/metabase`](../../base/metabase/) (which stay as standalone projects).

```
CSV seeds -> dbt (staging view -> mart table) -> PostgreSQL "warehouse" -> Metabase
                  ^
            Prefect deployment "dbt-hourly" (hourly + on demand)
```

## Services

| Service | Image | Port | Purpose |
|---|---|---|---|
| `postgres` | `postgres:17` | internal | One server, three databases: `warehouse` (data), `metabase`, `prefect` |
| `prefect-server` | built from `Dockerfile` (`prefecthq/prefect` + dbt) | 4200 | Prefect API and UI |
| `pipeline` | same image | - | Serves the flow `dbt-pipeline` as deployment `dbt-hourly` and runs dbt |
| `metabase` | `metabase/metabase:v0.64.1.3` | 3000 | BI / exploration UI |

dbt runs inside the `pipeline` container, in its own virtualenv (`/opt/dbt`) so its dependencies cannot clash with Prefect's.

## Quick start

```sh
cp .env.example .env
docker compose up -d --build
```

1. Open Prefect at <http://localhost:4200> -> **Deployments** -> `dbt-pipeline / dbt-hourly` -> **Run** -> **Quick run** (it also runs every hour). The flow runs `dbt seed`, `dbt run` and `dbt test`.
2. Open Metabase at <http://localhost:3000>, finish the setup wizard, then **Add a database -> PostgreSQL**: host `postgres`, port `5432`, database `warehouse`, user and password from `.env` (`platform` / `platform`).
3. Browse the `analytics` schema: `orders` (seed), `stg_orders` (view) and `revenue_by_country` (table).

`smoke-test.sh` (run by CI) does exactly this through the APIs: it starts a flow run, waits for it, checks the table in Postgres and queries it through Metabase.

## The dbt project

`dbt/` is a normal dbt project and is mounted into the container, so edits take effect on the next run without rebuilding:

| Path | Content |
|---|---|
| `dbt/seeds/orders.csv` | sample orders |
| `dbt/models/staging/stg_orders.sql` | cleaned view over the seed |
| `dbt/models/marts/revenue_by_country.sql` | aggregated table |
| `dbt/models/schema.yml` | `unique` / `not_null` tests |
| `dbt/profiles.yml` | connection, taken from the environment |

Run dbt by hand: `docker compose exec pipeline /opt/dbt/bin/dbt build --project-dir /dbt --profiles-dir /dbt`.
The Prefect flow lives in `flows/pipeline.py`; change the schedule in the `serve(...)` call at the bottom (restart `pipeline` afterwards).

## Configuration

Copy `.env.example` to `.env`. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `platform` | Database login (shared by dbt, Prefect and Metabase) |
| `POSTGRES_DB` | `warehouse` | The warehouse database |
| `METABASE_ENCRYPTION_KEY` | `change-me-...` | Encrypts credentials stored by Metabase - change it and keep it |
| `PREFECT_PORT` / `METABASE_PORT` | `4200` / `3000` | Host ports |
| `PREFECT_IMAGE` / `METABASE_IMAGE` | see `.env.example` | Image names / versions |
| `METABASE_ADMIN_EMAIL` / `METABASE_ADMIN_PASSWORD` | see `.env.example` | Only used by `smoke-test.sh` |

## Data and volumes

| Volume | Default name | Mounted at |
|---|---|---|
| `postgres_data` | `data-platform-postgres-dbt-prefect-metabase_postgres_data` | `postgres:/var/lib/postgresql/data` |

- **Rename:** set `VOLUME_PREFIX` (volumes are named `<VOLUME_PREFIX>_<volume>`).
- **Host folders instead:** `mkdir -p postgres_data && docker compose -f compose.yaml -f compose.bind.yaml up -d` (`DATA_DIR` sets the parent directory).
- The `metabase` and `prefect` databases are created by `initdb/10-databases.sh` only when the volume is empty. `docker compose down -v` deletes everything.

## Notes

- Development defaults only: change the passwords and the Metabase key before exposing the stack. Metabase sends usage statistics unless disabled (**Admin -> Settings**).
- The image is built locally and downloads dbt packages while building (including a parser binary from GitHub releases).
- Orchestrating with Airflow instead? See [`base/apache-airflow`](../../base/apache-airflow/); the dbt project can be reused as is.
