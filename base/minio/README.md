# MinIO

High-performance, S3-compatible object storage, using the hardened [Chainguard MinIO image](https://images.chainguard.dev/directory/image/minio/overview) (`cgr.dev/chainguard/minio`).

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
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

- The Chainguard image is distroless and runs as a non-root user (uid `65532`): `./minio_data` must be writable by that user (`sudo chown 65532:65532 minio_data` if you see permission errors).
- The image has no shell or `curl`, so no in-container healthcheck is defined. Use `mc` from `cgr.dev/chainguard/minio-client` to manage buckets.
- Change the default credentials before exposing the ports anywhere.
