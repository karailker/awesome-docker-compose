# Apache Airflow

Apache Airflow 3 with the CeleryExecutor, PostgreSQL and Redis. Based on the [official compose file](https://airflow.apache.org/docs/apache-airflow/3.0.0/docker-compose.yaml).

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `airflow-apiserver` | `apache/airflow:3.0.0` | 8080 | UI and API |
| `airflow-scheduler`, `airflow-dag-processor`, `airflow-triggerer` | `apache/airflow:3.0.0` | - | Core components |
| `airflow-worker` | `apache/airflow:3.0.0` | - | Celery worker |
| `airflow-init` | `apache/airflow:3.0.0` | - | One-shot: DB migration and admin user |
| `postgres` | `postgres:13` | internal | Metadata database |
| `redis` | `redis:7.2-bookworm` | internal | Celery broker |
| `flower` | `apache/airflow:3.0.0` | 5555 | Celery monitor (profile `flower`) |
| `airflow-cli` | `apache/airflow:3.0.0` | - | CLI helper (profile `debug`) |

## Quick start

```sh
cp .env.example .env
mkdir -p dags logs plugins
docker compose up airflow-init            # first run only
docker compose up -d
docker compose --profile flower up -d     # optional Celery monitor
```

- UI: <http://localhost:8080> (`airflow` / `airflow` by default)
- CLI: `docker compose run --rm airflow-cli airflow config list`

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | `mydatabase` / `myuser` / `mypassword` | Metadata database |
| `_AIRFLOW_WWW_USER_USERNAME` / `_PASSWORD` | `airflow` / `airflow` | Initial admin user |
| `AIRFLOW_JWT_SECRET` / `AIRFLOW_SECRET_KEY` | development placeholders | API JWT signing secret and web session key; generate your own |
| `AIRFLOW_FERNET_KEY` | empty | Encrypts connections and variables in the database |
| `AIRFLOW_IMAGE_NAME` | `apache/airflow:3.0.0` | Image |
| `AIRFLOW__CORE__LOAD_EXAMPLES` | `true` | Load example DAGs |
| `AIRFLOW_UID` | `50000` | Container user id (set to `$(id -u)` on Linux to avoid permission issues) |
| `AIRFLOW_PROJ_DIR` | `.` | Base directory of `dags/`, `logs/`, `config/`, `plugins/` |
| `_PIP_ADDITIONAL_REQUIREMENTS` | empty | Extra pip packages (quick tests only) |

## Notes

- Needs about 4 GB of RAM and 2 CPUs.
- Custom settings go in `config/airflow.cfg`.
- **Secrets:** `config/airflow.cfg` used to contain generated keys that every clone shared. They are gone: the JWT secret, the web session key and the Fernet key now come from `AIRFLOW_JWT_SECRET`, `AIRFLOW_SECRET_KEY` and `AIRFLOW_FERNET_KEY` (see `.env.example` for how to generate them). Without a `.env` the stack uses obvious development defaults and an empty Fernet key. Set your own before storing real connections or exposing the UI.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `postgres_data` | `apache-airflow_postgres_data` | `postgres:/var/lib/postgresql/data` |
| `redis_data` | `apache-airflow_redis_data` | `redis:/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `apache-airflow`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p postgres_data redis_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
