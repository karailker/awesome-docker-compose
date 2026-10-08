# Garage

Lightweight, geo-distributed, S3-compatible object store by [Deuxfleurs](https://garagehq.deuxfleurs.fr/) (AGPL-3.0). Small footprint, written in Rust, designed for self-hosting. This is a single-node development setup.

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `garage` | `dxflrs/garage:v2.4.1` | 3900 (S3), 3901 (RPC), 3902 (static web), 3903 (admin API) | Object storage |

## Quick start

```sh
cp .env.example .env      # optional
docker compose up -d
./init.sh my-bucket       # one-time: cluster layout + access key + bucket
```

`init.sh` assigns the node to the cluster layout (required before Garage accepts data), creates an access key (`dev-key`, allowed to create buckets), creates the bucket if you pass a name, and prints the key id and secret. It is idempotent.

```sh
export AWS_ACCESS_KEY_ID=<Key ID printed by init.sh>
export AWS_SECRET_ACCESS_KEY=<Secret key printed by init.sh>
export AWS_DEFAULT_REGION=garage
aws --endpoint-url http://localhost:3900 s3 ls s3://my-bucket
```

## Configuration

Everything is in [`config/garage.toml`](config/garage.toml): region (`garage`), ports, tokens and `rpc_secret`.

| Variable | Default | Description |
|----------|---------|-------------|
| `GARAGE_IMAGE` | `dxflrs/garage:v2.4.1` | Override the image/tag |
| `GARAGE_KEY_NAME` | `dev-key` | Name of the key created by `init.sh` |

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `garage_data` | `garage_garage_data` | `garage:/var/lib/garage/data` |
| `garage_meta` | `garage_garage_meta` | `garage:/var/lib/garage/meta` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `garage`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p garage_meta garage_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Notes

- **Replace `rpc_secret`, `admin_token` and `metrics_token`** in `garage.toml` before exposing anything (`openssl rand -hex 32`).
- Unlike MinIO, Garage has no built-in console and uses generated access keys rather than root credentials.
- The image is distroless (a single `/garage` binary), so manage it with `docker compose exec garage /garage <command>`.
- Tested in CI with a full S3 round trip (create bucket, put, get, list, delete).
