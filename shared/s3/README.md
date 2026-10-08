# Shared S3 helpers

Building blocks for projects that need an S3-compatible object store. They exist because MinIO Community Edition is unmaintained; every S3-using project now offers **RustFS** (default), **SeaweedFS** and **Garage**.

| File | Used by |
|---|---|
| `garage.toml` | `compose.garage.yaml` of each project (single node, S3 API on 9000, admin API on 3903) |
| `garage-init.sh` | the `garage-init` job: assigns the cluster layout, imports `S3_ACCESS_KEY` / `S3_SECRET_KEY`, creates the buckets in `S3_BUCKETS` and grants the key access. Idempotent, POSIX sh, runs in `curlimages/curl` |

## The pattern

`compose.yaml` defines `s3` (RustFS) and a `create-bucket` job (`amazon/aws-cli`: `head-bucket || mb`) that the apps depend on. `compose.seaweedfs.yaml` and `compose.garage.yaml` override the image, environment, ports, volumes and healthcheck of `s3`; the Garage one adds `garage-init` and makes `create-bucket` wait for it. The S3 API is always `http://s3:9000` in the network, so applications are identical across variants. Overrides use `!override` / `!reset` and need Docker Compose 2.24 or newer.

## Garage specifics

- Access keys must be `GK` + 24 hex characters, secrets 64 hex characters (the project defaults already are).
- Garage cannot create buckets from an S3 client without the right permission, so buckets are created through the admin API by `garage-init`.
- The image is distroless: no shell, no container healthcheck. Readiness is handled by `garage-init`.
- `rpc_secret` and `admin_token` in `garage.toml` / `GARAGE_ADMIN_TOKEN` are development defaults - change them for anything real.
