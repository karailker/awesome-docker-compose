# RustFS

High-performance, S3-compatible object storage written in Rust (Apache-2.0). A drop-in replacement for the discontinued MinIO Community Edition: same ports (9000 API, 9001 console) and a similar environment-variable model.

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `rustfs` | `rustfs/rustfs:1.0.1` | 9000 (S3 API), 9001 (Console) | Object storage |

## Quick start

```sh
cp .env.example .env
docker compose up -d
```

- Console: <http://localhost:9001>
- S3 endpoint: <http://localhost:9000>
- Credentials: `RUSTFS_ACCESS_KEY` / `RUSTFS_SECRET_KEY` (default `rustfsadmin` / `rustfsadmin`)

```sh
aws --endpoint-url http://localhost:9000 s3 mb s3://my-bucket
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `RUSTFS_ACCESS_KEY` | `rustfsadmin` | Root access key |
| `RUSTFS_SECRET_KEY` | `rustfsadmin` | Root secret key |
| `RUSTFS_IMAGE` | `rustfs/rustfs:1.0.1` | Override the image/tag |

## Notes

- Data lives in the named volume `rustfs_data`; `docker compose down -v` deletes it.
- The container runs as uid `10001`.
- Replace the default credentials before exposing the ports. RustFS logs a warning while defaults are in use.
- Tested in CI with a full S3 round trip (create bucket, put, get, list, delete).
