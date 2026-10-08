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

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `rustfs_data` | `rustfs_rustfs_data` | `rustfs:/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `rustfs`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p rustfs_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Notes

- The container runs as uid `10001`.
- Replace the default credentials before exposing the ports. RustFS logs a warning while defaults are in use.
- Tested in CI with a full S3 round trip (create bucket, put, get, list, delete).
