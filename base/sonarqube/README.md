# SonarQube

SonarQube Community Build for continuous code quality and security inspection, backed by PostgreSQL.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `sonarqube` | `sonarqube:25.10.0.114319-community` | 9000 | Analysis server and UI |
| `postgres` | `postgres:17` | internal | Database |

## Quick start

```sh
sudo sysctl -w vm.max_map_count=262144   # Linux hosts, required by the embedded Elasticsearch
cp .env.example .env
docker compose up -d
```

- UI: <http://localhost:9000> (default login `admin` / `admin`, you must change it on first login)

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `SONARQUBE_IMAGE` | `sonarqube:25.10.0.114319-community` | Image |
| `POSTGRES_IMAGE` | `postgres:17` | Database image |
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | `sonar` / `sonar` / `sonarpass` | Database settings |

## Notes

- SonarQube's embedded Elasticsearch also needs at least 65535 open file descriptors on the Docker host.
- Needs about 4 GB of RAM.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `postgres_data` | `sonarqube_postgres_data` | `postgres:/var/lib/postgresql/data` |
| `sonarqube_data` | `sonarqube_sonarqube_data` | `sonarqube:/opt/sonarqube/data` |
| `sonarqube_extensions` | `sonarqube_sonarqube_extensions` | `sonarqube:/opt/sonarqube/extensions` |
| `sonarqube_logs` | `sonarqube_sonarqube_logs` | `sonarqube:/opt/sonarqube/logs` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `sonarqube`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p sonarqube_data sonarqube_extensions sonarqube_logs postgres_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
