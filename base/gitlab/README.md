# GitLab CE

GitLab Community Edition with external PostgreSQL and Redis.

> Work in progress (see the roadmap in the root README). Needs at least 4 GB of RAM and several minutes for the first start.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `gitlab` | `gitlab/gitlab-ce:latest` | 8090 (HTTP), 8093 (HTTPS), 2222 (SSH) | GitLab |
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
- Data is bind-mounted to `./config`, `./logs`, `./data`, `./postgresql` and `./redis`.

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
