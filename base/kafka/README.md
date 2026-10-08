# Kafka (KRaft) with Kafka UI

Single-node Apache Kafka running in **KRaft mode** (no Zookeeper), using `confluentinc/cp-kafka`, plus an optional Kafka UI.

> Recent Confluent images (8.x) no longer support Zookeeper, so the previous Zookeeper-based setup was removed.

## Services

| Service | Image | Ports | Purpose |
|---------|-------|-------|---------|
| `kafka` | `confluentinc/cp-kafka:8.0.8` | 9092 | Broker + controller |
| `kafka-ui` | `provectuslabs/kafka-ui` | 8080 | Web UI (profile `kafkaui`) |

## Quick start

```sh
docker compose up -d                       # broker only
docker compose --profile kafkaui up -d     # broker + UI (http://localhost:8080)
```

Connect from the host with `localhost:9092`; from other containers on the `kafka_network` network use `kafka:29092`.

```sh
docker compose exec kafka kafka-topics --bootstrap-server localhost:29092 --create --topic demo
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `KAFKA_IMAGE` | `confluentinc/cp-kafka:8.0.8` | Broker image |
| `KAFKA_UI_IMAGE` | `provectuslabs/kafka-ui:latest` | UI image |
| `KAFKA_CLUSTER_ID` | development value | Generate your own with `kafka-storage random-uuid` |

## Data and volumes

Data is kept in Docker-managed named volumes, so nothing has to be created before the first start.

| Volume | Default name | Mounted at |
|---|---|---|
| `kafka_data` | `kafka_kafka_data` | `kafka:/var/lib/kafka/data` |

- **Rename:** set `VOLUME_PREFIX` in `.env` (or the environment). Volumes are named `<VOLUME_PREFIX>_<volume>`; the default prefix is `kafka`.
- **Host folders instead:** use the override file, optionally with `DATA_DIR` (default: this directory):
  ```sh
  mkdir -p kafka_data
  docker compose -f compose.yaml -f compose.bind.yaml up -d
  ```
- `docker compose down -v` deletes the volumes (and your data).
