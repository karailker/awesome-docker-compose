# Elasticsearch cluster with Kibana

Three-node Elasticsearch 8 cluster with TLS, Kibana and an APM server. Based on [evermight/elastic-cluster-docker-compose](https://github.com/evermight/elastic-cluster-docker-compose/blob/master/docker-compose.yml).

> **APM:** the APM server reads `config/apm-server.yml` (the image does not take `output.elasticsearch.*` settings from environment variables). `smoke-test.sh` sends a transaction to the APM server and requires it to appear in the `traces-apm*` data stream.

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `setup` | `elasticsearch` | - | One-shot job: generates certificates and sets the `kibana_system` password |
| `es01`, `es02`, `es03` | `docker.elastic.co/elasticsearch/elasticsearch` | 9200 (es01) | Cluster nodes |
| `kibana` | `docker.elastic.co/kibana/kibana` | 5601 | Kibana UI |
| `apm-server` | `docker.elastic.co/apm/apm-server` | 8200 | APM intake |

## Quick start

```sh
sudo sysctl -w vm.max_map_count=262144   # Linux hosts, required by Elasticsearch
cp .env.example .env
docker compose up -d
```

- Elasticsearch: <https://localhost:9200> (user `elastic`, password `ELASTIC_PASSWORD`; self-signed certificate, use `curl -k`)
- Kibana: <http://localhost:5601>

## Configuration

Copy `.env.example` to `.env` and adjust. Every variable has a default in `compose.yaml`.

| Variable | Default | Description |
|---|---|---|
| `ELASTIC_PASSWORD` | `elasticpassword` | Password of the `elastic` user (at least 6 characters) |
| `KIBANA_PASSWORD` | `kibanasystempassword` | Password of `kibana_system` |
| `STACK_VERSION` | `8.15.0` | Elastic Stack version |
| `CLUSTER_NAME` | `docker-cluster` | Cluster name |
| `LICENSE` | `basic` | `basic` or `trial` |
| `ES_PORT` | `9200` | Host port for Elasticsearch |
| `KIBANA_PORT` | `5601` | Host port for Kibana |
| `MEM_LIMIT` | `1073741824` | Memory limit per container in bytes |

## Notes

- Needs several GB of free RAM (3 Elasticsearch nodes + Kibana + APM).
- Change both passwords before exposing the stack.

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `apm_data` | `elasticsearch_apm_data` | `apm-server:/usr/share/apm-server/data` |
| `certs_data` | `elasticsearch_certs_data` | `apm-server:/usr/share/apm-server/config/certs`, `es01:/usr/share/elasticsearch/config/certs`, `es02:/usr/share/elasticsearch/config/certs`, `es03:/usr/share/elasticsearch/config/certs`, `kibana:/usr/share/kibana/config/certs`, `setup:/usr/share/elasticsearch/config/certs` |
| `es01_data` | `elasticsearch_es01_data` | `es01:/usr/share/elasticsearch/data` |
| `es02_data` | `elasticsearch_es02_data` | `es02:/usr/share/elasticsearch/data` |
| `es03_data` | `elasticsearch_es03_data` | `es03:/usr/share/elasticsearch/data` |
| `kibana_data` | `elasticsearch_kibana_data` | `kibana:/usr/share/kibana/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `elasticsearch`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p es01_data es02_data es03_data kibana_data certs_data apm_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
