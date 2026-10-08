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

- **[MLflow with MinIO and Postgres](stacks/mlflow-minio-postgres-pgadmin/)**: A stack for managing the machine learning lifecycle, including MinIO for object storage and Postgres for metadata storage.
- **[MLflow-OIDC with Keycloak, MinIO, and Postgres](stacks/mlflow-oidc-keycloak-minio-postgres-pgadmin/)**: Enterprise MLflow setup with OpenID Connect authentication via Keycloak, object storage with MinIO, and PostgreSQL for metadata.

> **Note**: ElasticAPM integration for ElasticSearch is under development and may not work properly yet. Updates are in progress.

## Testing

Every pull request runs [GitHub Actions](.github/workflows/ci.yml): YAML/JSON/shell/workflow linting, `docker compose config` for each project (with `.env.example` and with defaults only), image availability checks, container smoke tests (`docker compose up --wait`), and real S3 round trips against RustFS, SeaweedFS and Garage. Resource-hungry stacks (Elasticsearch, Milvus, SonarQube, Nexus, Prefect, Airflow, Feast and the MLflow and W&B stacks) are smoke tested weekly by [heavy-smoke.yml](.github/workflows/heavy-smoke.yml). Run a project locally with `scripts/smoke.sh base/<name>`.

## Roadmap

### Recently Completed ✅
- ✅ **[SonarQube](base/sonarqube/)** - Code quality and security analysis
- ✅ **[Sonatype Nexus](base/nexus/)** - Artifact repository manager
- ✅ **[FastAPI Example App](base/fastapi/)** - Modern Python API framework
- ✅ **[InfluxDB with Telegraf](base/influxdb/)** - Time-series database with metrics collection agent
- ✅ **[ClickHouse with Tabix](base/clickhouse/)** - High-performance columnar analytics database
- ✅ **[CockroachDB](base/cockroachdb/)** - Distributed SQL database for cloud-native apps

### Upcoming Features
- 🚧 **[GitLab](base/gitlab/)** - DevOps platform
- ⬜ **Apache Superset** - Business intelligence web application
- ⬜ **Great Expectations** - Data validation and profiling
- ⬜ **BentoML** - ML model serving framework
- ⬜ **Nvidia Triton** - Inference server
- 🚧 **[Weights & Biases](stacks/wandb-minio-postgres/)** - ML experiment tracking

### Postponed
-  🔄 **dbt Core** - Data transformation tool

### Legend:
- ✅ Completed  
- ⬜ Pending  
- ❌ Canceled  
- 🔄 Postponed  
- 🚧 In Progress 

## Usage

Every configuration is self-contained. Pick a directory, create your `.env`, and start it:

```sh
cd base/postgres          # or any other directory under base/ or stacks/
cp .env.example .env      # if the directory has one; adjust the values
docker compose up -d
docker compose down       # stop (add -v to remove volumes)
```

- Optional components (admin UIs, init jobs) are behind Compose profiles, e.g. `docker compose --profile pgadmin up -d`. Each README lists the profiles.
- Data is stored in `./<name>_data` directories or named volumes (ignored by git).
- All credentials in `.env.example` and the compose defaults are for **local development only**: change them before exposing anything.
- Requires Docker Compose v2 (`docker compose`).

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.