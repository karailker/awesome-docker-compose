# GitLab CE

GitLab Community Edition with external PostgreSQL and Redis.

> Work in progress (see the roadmap in the root README). Needs at least 4 GB of RAM and several minutes for the first start. The Omnibus settings in `compose.yaml` use a small footprint (`puma['worker_processes'] = 0`, `sidekiq['concurrency'] = 10`, Prometheus off, `shm_size: 256m`); remove them for a multi-user instance. The external PostgreSQL runs with `max_locks_per_transaction=256`: with the default of 64 GitLab's migrations fail with `ERROR: out of shared memory` and the container restarts in a loop.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `gitlab` | `gitlab/gitlab-ce:19.4.1-ce.0` | 8090 (HTTP), 8093 (HTTPS), 2222 (SSH) | GitLab |
| `postgresql` | `postgres:17` | internal | Database |
| `redis` | `redis:7` | internal | Cache and queues |

## Quick start

```sh
docker compose up -d
docker compose logs -f gitlab      # wait for "gitlab Reconfigured!" / healthy
```

- UI: <http://localhost:8090>
- Login: `root` / `S3cureP@ssw0rd_2025` (set in `compose.yaml` via `GITLAB_ROOT_PASSWORD`)
- Git over SSH: port `2222`

## Notes

- The hostname is `gitlab.local` and `external_url` is `http://gitlab.local`; add `127.0.0.1 gitlab.local` to your hosts file for clone URLs to resolve.
- Credentials are hard-coded in `compose.yaml`: change them before real use.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `gitlab_config` | `gitlab_gitlab_config` | `gitlab:/etc/gitlab` |
| `gitlab_data` | `gitlab_gitlab_data` | `gitlab:/var/opt/gitlab` |
| `gitlab_logs` | `gitlab_gitlab_logs` | `gitlab:/var/log/gitlab` |
| `postgresql_data` | `gitlab_postgresql_data` | `postgresql:/var/lib/postgresql/data` |
| `redis_data` | `gitlab_redis_data` | `redis:/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `gitlab`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p postgresql redis config logs data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
