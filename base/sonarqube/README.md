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

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
