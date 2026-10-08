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

## Notes

- **Replace `rpc_secret`, `admin_token` and `metrics_token`** in `garage.toml` before exposing anything (`openssl rand -hex 32`).
- Unlike MinIO, Garage has no built-in console and uses generated access keys rather than root credentials.
- The image is distroless (a single `/garage` binary), so manage it with `docker compose exec garage /garage <command>`.
- Data lives in the named volumes `garage_meta` and `garage_data`.
- Tested in CI with a full S3 round trip (create bucket, put, get, list, delete).
