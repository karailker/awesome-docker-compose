# Elasticsearch cluster with Kibana

Three-node Elasticsearch 8 cluster with TLS, Kibana and an APM server. Based on [evermight/elastic-cluster-docker-compose](https://github.com/evermight/elastic-cluster-docker-compose/blob/master/docker-compose.yml).

> **APM:** the APM server integration is under development and may not work yet (see the root README).

## Services

| Service | Image | Port(s) | Purpose |
|---|---|---|---|
| `setup` | `elasticsearch` | - | One-shot job: generates certificates and sets the `kibana_system` password |
| `es01`, `es02`, `es03` | `docker.elastic.co/elasticsearch/elasticsearch` | 9200 (es01) | Cluster nodes |
| `kibana` | `docker.elastic.co/kibana/kibana` | 5601 | Kibana UI |
| `apm-server` | `docker.elastic.co/apm/apm-server` | 8200 | APM intake |

## Quick start

```sh
mkdir -p apm_data certs_data es01_data es02_data es03_data kibana_data   # bind-mounted data directories must exist
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

## Stop and clean up

```sh
docker compose down        # keep data
docker compose down -v     # also remove named volumes
```
