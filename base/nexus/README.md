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
- Data is stored in the `nexus_data` volume.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
