# Awesome Docker Compose

This repository contains a collection of Docker Compose configurations for various services.

## Available Configurations

### Base
These are individual service setups that can be used as building blocks for your projects:

- **[Postgres with pgAdmin](base/postgres/)**: PostgreSQL database with pgAdmin for management.
- **[Postgres-pgVector with pgAdmin](base/pgvector/)**: PostgreSQL with pgVector extension and pgAdmin.
- **[Kafka with Kafka UI](base/kafka/)**: Kafka message broker with a management UI.
- **[MinIO](base/minio/)**: High-performance object storage service.
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
- **[dbt Core](base/dbt-core/)**: Data transformation tool for analytics engineering.
- **[GitLab](base/gitlab/)**: DevOps platform with integrated CI/CD, project management, and more.
- **[SonarQube](base/sonarqube/)**: Code quality and security analysis platform for continuous inspection.
- **[Sonatype Nexus](base/nexus/)**: Universal artifact repository manager for storing and distributing software components. 

### Stacks
These are pre-configured setups combining multiple services for specific use cases:

- **[MLflow with MinIO and Postgres](stacks/mlflow-minio-postgres-pgadmin/)**: A stack for managing the machine learning lifecycle, including MinIO for object storage and Postgres for metadata storage.
- **[MLflow-OIDC with Keycloak, MinIO, and Postgres](stacks/mlflow-oidc-keycloak-minio-postgres-pgadmin/)**: Enterprise MLflow setup with OpenID Connect authentication via Keycloak, object storage with MinIO, and PostgreSQL for metadata.

> **Note**: ElasticAPM integration for ElasticSearch is under development and may not work properly yet. Updates are in progress.

## Roadmap

### Recently Completed ✅
- ✅ **[MLFlow Stack](stacks/mlflow-minio-postgres-pgadmin/)** - Basic ML lifecycle management
- ✅ **[MLFlow-OIDC-Keycloak Stack](stacks/mlflow-oidc-keycloak-minio-postgres-pgadmin/)** - Enterprise MLflow with authentication
- ✅ **[Apache Airflow](base/apache-airflow/)** - Workflow orchestration platform
- ✅ **[Feast](base/feast/)** - ML feature store
- ✅ **[Valkey](base/valkey/)** - Redis alternative
- ✅ **[Prefect](base/prefect/)** - Modern workflow orchestration
- ✅ **[SonarQube](base/sonarqube/)** - Code quality and security analysis
- ✅ **[Sonatype Nexus](base/nexus/)** - Artifact repository manager

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

To use any of the configurations, navigate to the respective directory and run:

```sh
docker-compose up
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.