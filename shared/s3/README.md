# Shared S3 helpers

Building blocks for projects that need an S3-compatible object store. They exist because MinIO Community Edition is unmaintained; every S3-using project now offers **RustFS** (default), **SeaweedFS** and **Garage**.

| File | Used by |
|---|---|
| `garage.toml` | `compose.garage.yaml` of each project (single node, S3 API on 9000, admin API on 3903) |
| `garage-init.sh` | the `garage-init` job: assigns the cluster layout, imports `S3_ACCESS_KEY` / `S3_SECRET_KEY`, creates the buckets in `S3_BUCKETS` and grants the key access. Idempotent, POSIX sh, runs in `curlimages/curl` |

## The pattern

`shared/s3/compose.yaml` holds service templates: `s3` (RustFS), `create-bucket` (`amazon/aws-cli`: `head-bucket || mb`) and `garage-init`. A project pulls them in with `extends` and adds what is project specific (network, bucket names):

```yaml
services:
  s3:
    extends: {file: ../../shared/s3/compose.yaml, service: s3}
    networks: [my-network]
  create-bucket:
    extends: {file: ../../shared/s3/compose.yaml, service: create-bucket}
    environment:
      S3_BUCKETS: my-bucket   # space separated
    networks: [my-network]
volumes:
  s3_data:
    name: ${VOLUME_PREFIX:-my-project}_s3_data
```

and makes the apps `depends_on: create-bucket: {condition: service_completed_successfully}`. `compose.seaweedfs.yaml` and `compose.garage.yaml` override the image, environment, ports, volumes and healthcheck of `s3`; the Garage one adds `garage-init` (also from the template) and makes `create-bucket` wait for it. The S3 API is always `http://s3:9000` in the network, so applications are identical across variants. Overrides use `!override` / `!reset` and need Docker Compose 2.24 or newer.

**Why `extends` and not `include:`?** `include` cannot be customised by the including file (a service defined in both files is a conflict), so the project-specific parts - the network, the bucket list and its default - cannot be set. It would also force every project onto the default network and make `.env` mandatory for the defaults. `extends` shares the same definitions and lets each project add its own bits.

## Garage specifics

- Access keys must be `GK` + 24 hex characters, secrets 64 hex characters (the project defaults already are).
- Garage cannot create buckets from an S3 client without the right permission, so buckets are created through the admin API by `garage-init`.
- The image is distroless: no shell, no container healthcheck. Readiness is handled by `garage-init`.
- `rpc_secret` and `admin_token` in `garage.toml` / `GARAGE_ADMIN_TOKEN` are development defaults - change them for anything real.
