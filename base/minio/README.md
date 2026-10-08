# MinIO

> **Project status:** the open-source MinIO Community Edition is **no longer maintained**. MinIO, Inc. stopped distributing binaries and images in late 2025, put the repository in maintenance mode, and in February 2026 declared it unmaintained (no features, bug fixes or security patches). Development continues only in the commercial **AIStor** product.
> The Chainguard image used here is rebuilt from that frozen source, so treat this setup as legacy and prefer one of the maintained alternatives: **[RustFS](../rustfs/)**, **[SeaweedFS](../seaweedfs/)** or **[Garage](../garage/)**. See [Choosing an S3 store](#alternatives) below.

High-performance, S3-compatible object storage, using the hardened [Chainguard MinIO image](https://images.chainguard.dev/directory/image/minio/overview) (`cgr.dev/chainguard/minio`).

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `minio-init-perms` | `busybox:1.37` | - | One-shot: sets volume ownership for MinIO |
| `minio` | `cgr.dev/chainguard/minio:latest` | 9000 (S3 API), 9001 (Console) | Object storage |

## Quick start

```sh
cp .env.example .env      # optional, defaults are minioadmin / minioadmin
mkdir -p minio_data       # bind-mount target for the volume
docker compose up -d
```

- Console: <http://localhost:9001>
- S3 endpoint: <http://localhost:9000>

Stop: `docker compose down` (add `-v` to drop the volume definition; data stays in `./minio_data`).

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_ROOT_USER` | `minioadmin` | Root access key |
| `MINIO_ROOT_PASSWORD` | `minioadmin` | Root secret key (min. 8 chars) |

## Notes

- The MinIO image is distroless and runs as a non-root user (uid `65532`). The one-shot `minio-init-perms` service (busybox) fixes the ownership of the data volume before MinIO starts, so no manual `chown` is needed.
- The image has no shell or `curl`, so no in-container healthcheck is defined. Use `mc` from `cgr.dev/chainguard/minio-client` to manage buckets.
- Change the default credentials before exposing the ports anywhere.

## Alternatives

| Option | License | Console UI | Notes |
|--------|---------|-----------|-------|
| [RustFS](../rustfs/) | Apache-2.0 | yes | Closest drop-in replacement (ports 9000/9001, similar env vars) |
| [SeaweedFS](../seaweedfs/) | Apache-2.0 | master/filer UI | Scales from a single node to large clusters; also offers a filer and FUSE mount |
| [Garage](../garage/) | AGPL-3.0 | no | Very small footprint, built for self-hosting and multi-site; needs a one-time layout init |
| MinIO AIStor | Proprietary (MinIO Commercial License) | yes | The vendor's successor product. The free tier is single-node only and needs a license key (`MINIO_LICENSE`) from SUBNET; not open source and not usable in a plain `docker compose up`. Not included here |
