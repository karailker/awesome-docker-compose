# Weights & Biases Local + MinIO + MySQL

Self-hosted [W&B Local](https://docs.wandb.ai/guides/hosting) for experiment tracking, with MinIO as S3-compatible artifact storage and MySQL as the metadata database.

> Status: work in progress (see the roadmap in the root README). W&B Local may require a license/login for full functionality.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| `wandb` | `wandb/local` | 8088 | W&B UI/API |
| `minio` | `cgr.dev/chainguard/minio` | 9000, 9001 | Object storage |
| `createbuckets` | `cgr.dev/chainguard/minio-client:latest-dev` | - | Creates the bucket (profile `init`) |
| `mysql` | `mysql:8.4` | 3306 | Metadata store |

## Quick start

```sh
cp .env.example .env
docker compose up -d minio
docker compose --profile init up createbuckets   # creates ${MINIO_BUCKET_NAME}
docker compose up -d
```

- W&B: <http://localhost:8088>
- MinIO Console: <http://localhost:9001>

Point the client at it:

```sh
wandb login --host http://localhost:8088
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` | `minioadmin` | MinIO credentials |
| `MINIO_BUCKET_NAME` | `wandb-bucket` | Bucket used by W&B |
| `AWS_REGION` | `us-east-1` | S3 region |
| `MYSQL_DATABASE` / `MYSQL_USER` / `MYSQL_PASSWORD` / `MYSQL_ROOT_PASSWORD` | `wandb` / `wandbuser` / `wandbpass` / `rootpass` | MySQL settings |

## Notes

- Data is kept in named Docker volumes (`wandb_data`, `minio_data`, `mysql_data`); `docker compose down -v` deletes it.
- The MinIO image is distroless and has no shell, so it has no healthcheck; `wandb` only waits for it to start.
- Development defaults only; change all passwords before exposing the stack.
