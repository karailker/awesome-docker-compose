# Sonatype Nexus Repository

Sonatype Nexus Repository OSS, a universal artifact repository manager (Maven, npm, PyPI, Docker, ...).

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `nexus` | `sonatype/nexus3:3.69.0` | 8081 | Repository manager |

## Quick start

```sh
cp .env.example .env
docker compose up -d
docker compose exec nexus cat /nexus-data/admin.password   # initial admin password
```

- UI: <http://localhost:8081> (user `admin`, password from the command above; you are asked to change it on first login)

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `NEXUS_IMAGE` | `sonatype/nexus3:3.69.0` | Image |
| `NEXUS_CONTEXT` | `/` | Context path |

## Notes

- The first start takes one to two minutes; the healthcheck reports healthy once the status endpoint answers.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `nexus_data` | `nexus_nexus_data` | `nexus:/nexus-data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `nexus`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p nexus_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
