# SeaweedFS

Distributed storage system with an S3-compatible gateway (Apache-2.0). This setup runs master, volume server, filer and S3 gateway in a single container (`weed server -filer -s3`), which is ideal for development and small installs.

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `seaweedfs` | `chrislusf/seaweedfs:latest` | 9333 (Master UI), 8888 (Filer UI), 8333 (S3 API) | All-in-one SeaweedFS |

## Quick start

```sh
cp .env.example .env      # optional
docker compose up -d
```

- S3 endpoint: <http://localhost:8333>
- Master UI: <http://localhost:9333>
- Filer UI: <http://localhost:8888>

```sh
AWS_ACCESS_KEY_ID=seaweedadmin AWS_SECRET_ACCESS_KEY=seaweedadmin \
  aws --endpoint-url http://localhost:8333 s3 mb s3://my-bucket
```

## Configuration

S3 identities are defined in [`config/s3.json`](config/s3.json) (default key `seaweedadmin` / `seaweedadmin`, full access). Add more identities with restricted `actions` (e.g. `Read`, `Write`, `List`, `Admin`) and restart the container.

| Variable | Default | Description |
|----------|---------|-------------|
| `SEAWEEDFS_IMAGE` | `chrislusf/seaweedfs:latest` | Pin a release tag for reproducible deployments |

## Notes

- Data lives in the named volume `seaweedfs_data`; `docker compose down -v` deletes it.
- For a production cluster run separate master / volume / filer / s3 services (see the SeaweedFS wiki).
- Change the credentials in `config/s3.json` before exposing the ports.
- Tested in CI with a full S3 round trip (create bucket, put, get, list, delete).
