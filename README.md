# Awesome Docker Compose

This repository contains a collection of Docker Compose configurations for various services.

## Available Configurations

### Base
These are individual service setups that can be used as building blocks for your projects:

- **[Postgres with pgAdmin](base/postgres/)**: PostgreSQL database with pgAdmin for management.
- **[Postgres-pgVector with pgAdmin](base/pgvector/)**: PostgreSQL with pgVector extension and pgAdmin.
- **[Kafka with Kafka UI](base/kafka/)**: Single-node Kafka (KRaft, no Zookeeper) with a management UI.
- **[MinIO](base/minio/)** *(legacy, unmaintained)*: S3-compatible object storage. The MinIO Community Edition is no longer maintained since February 2026; prefer one of the alternatives below.
- **[RustFS](base/rustfs/)**: S3-compatible object storage written in Rust; closest drop-in MinIO replacement (Apache-2.0).
- **[SeaweedFS](base/seaweedfs/)**: Scalable distributed storage with an S3 gateway and filer (Apache-2.0).
- **[Garage](base/garage/)**: Lightweight, self-hostable S3-compatible store by Deuxfleurs (AGPL-3.0).
- **[Redis with RedisInsight](base/redis/)**: In-memory data store with a management UI.
- **[Valkey](base/valkey/)**: Drop-in Redis replacement managed by the Linux Foundation.
- **[RabbitMQ](base/rabbitmq/)**: Reliable messaging between distributed systems.
- **[Metabase](base/metabase/)**: Simple self-service BI on PostgreSQL, with a sample database to explore.
- **[Apache Superset](base/superset/)**: BI platform with SQL Lab and dashboards on PostgreSQL + Valkey, with a sample database to explore.
- **[Qdrant Vector DB](base/qdrant/)**: Optimized for storing and searching high-dimensional vectors.
- **[Milvus Vector DB](base/milvus/)**: Open-source vector database for similarity search.
- **[ElasticSearch with Kibana](base/elasticsearch/)**: Distributed search engine with Kibana for visualization.
- **[Grafana with Prometheus](base/grafana/)**: Metric collection, storage, and visualization.
- **[MongoDB with Mongo-Express](base/mongodb/)**: MongoDB paired with a web-based management interface.
- **[MySQL with Adminer and phpMyAdmin](base/mysql/)**: MySQL with Adminer and phpMyAdmin for administration.
- **[Apache Airflow](base/apache-airflow/)**: Platform to programmatically author, schedule, and monitor workflows.
- **[Prefect](base/prefect/)**: Workflow orchestration tool for automating and managing data workflows.
- **[Feast](base/feast/)**: Open-source feature store for managing and serving ML features in production.
- **[GitLab](base/gitlab/)**: DevOps platform with integrated CI/CD, project management, and more.
- **[SonarQube](base/sonarqube/)**: Code quality and security analysis platform for continuous inspection.
- **[Sonatype Nexus](base/nexus/)**: Universal artifact repository manager for storing and distributing software components. 
- **[FastAPI Example App](base/fastapi/)**: Modern Python web framework for building high-performance APIs with automatic documentation.
- **[InfluxDB with Telegraf](base/influxdb/)**: Time-series database optimized for IoT and monitoring data with metrics collection agent.
- **[ClickHouse with Tabix](base/clickhouse/)**: High-performance columnar database for analytics with web-based query interface.
- **[CockroachDB](base/cockroachdb/)**: Distributed SQL database designed for cloud-native applications with strong consistency.

### Stacks
These are pre-configured setups combining multiple services for specific use cases:

- **[MLflow with S3 store (RustFS/SeaweedFS/Garage) and Postgres](stacks/mlflow-minio-postgres-pgadmin/)**: A stack for managing the machine learning lifecycle, including an S3-compatible object store (RustFS by default) and Postgres for metadata storage.
- **[MLflow-OIDC with Keycloak, S3 store, and Postgres](stacks/mlflow-oidc-keycloak-minio-postgres-pgadmin/)**: Enterprise MLflow setup with OpenID Connect authentication via Keycloak, object storage on RustFS/SeaweedFS/Garage, and PostgreSQL for metadata.

- **[Data platform (PostgreSQL + dbt + Prefect + Metabase)](stacks/data-platform-postgres-dbt-prefect-metabase/)**: Warehouse, transformations, scheduling and BI in one stack, with a sample dbt project and an end-to-end test.
- **[LGTM observability (Loki, Grafana, Tempo, Prometheus + OpenTelemetry Collector)](stacks/lgtm-observability/)**: Logs, metrics and traces through one OTLP endpoint, with provisioned data sources, trace-to-log links and an overview dashboard.
- **[Local RAG / LLM (Ollama + Open WebUI + Qdrant)](stacks/rag-ollama-openwebui-qdrant/)**: Private chat UI with document question answering; Ollama runs the models, Qdrant stores the embeddings.
- **[Weights & Biases Local with S3 store and MySQL](stacks/wandb-minio-postgres/)**: Self-hosted W&B experiment tracking with S3-compatible artifact storage.

> **Note**: ElasticAPM integration for ElasticSearch is under development and may not work properly yet. Updates are in progress.

## Testing

Every pull request runs [GitHub Actions](.github/workflows/ci.yml): YAML/JSON/shell/workflow linting, `docker compose config` for each project (with `.env.example` and with defaults only), image availability checks, container smoke tests (`docker compose up --wait`), and real S3 round trips against RustFS, SeaweedFS and Garage. Resource-hungry stacks (Elasticsearch, Milvus, SonarQube, Nexus, Prefect, Airflow, Feast and the MLflow and W&B stacks) are smoke tested weekly by [heavy-smoke.yml](.github/workflows/heavy-smoke.yml). Security checks run on every pull request too: gitleaks over the full history, Trivy for secrets and Dockerfile misconfiguration, and a compose policy check (no privileged containers, host networking or Docker socket mounts). A weekly workflow reports vulnerabilities in the pinned images.

### Shortcuts

`make help` lists them. The common ones:

```sh
make up P=base/postgres        # start a project (creates .env from .env.example)
make smoke P=base/postgres     # start, wait until healthy, tear down (what CI does)
make check                     # fast checks: lint, compose config, pinned versions, policy
make secrets                   # gitleaks over the whole history
```

## Roadmap

The full picture (verified status of every project, blocked items, known issues and proposals) is in **[ROADMAP.md](ROADMAP.md)**. Short version:

- ✅ **Done:** LGTM observability stack, Ollama + Open WebUI + Qdrant RAG stack, SonarQube, Sonatype Nexus, FastAPI example, InfluxDB + Telegraf, ClickHouse + Tabix, CockroachDB, RustFS, SeaweedFS, Garage, Weights & Biases Local
- 🚧 **In progress:** [GitLab](base/gitlab/) (starts and is tested weekly; credentials and `external_url` still need work)
- ⬜ **Pending:** Apache Superset, BentoML
- 🔄 **Postponed:** dbt Core
- ⛔ **Blocked / needs a design decision:** Nvidia Triton (GPU, huge image, not testable on hosted runners), Great Expectations (a library, not a service)

Legend: ✅ completed · ⬜ pending · 🔄 postponed · 🚧 in progress · ⛔ blocked

## Usage

Every configuration is self-contained. Pick a directory, create your `.env`, and start it:

```sh
cd base/postgres          # or any other directory under base/ or stacks/
cp .env.example .env      # if the directory has one; adjust the values
docker compose up -d
docker compose down       # stop (add -v to also delete the data volumes)
```

- Optional components (admin UIs, init jobs) are behind Compose profiles, e.g. `docker compose --profile pgadmin up -d`. Each README lists the profiles.
- **Data lives in named Docker volumes**, so a fresh clone works without creating any directories. Their names are `<VOLUME_PREFIX>_<volume>` (the prefix defaults to the project directory name; set `VOLUME_PREFIX` in `.env` to change it).
- **Want the data in a host folder?** Every project ships a `compose.bind.yaml` override: `docker compose -f compose.yaml -f compose.bind.yaml up -d` (create the directories listed in the file first; `DATA_DIR` moves them elsewhere).
- All credentials in `.env.example` and the compose defaults are for **local development only**: change them before exposing anything.
- Requires Docker Compose v2 (`docker compose`).

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.