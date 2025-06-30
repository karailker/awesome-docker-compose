# Awesome Docker Compose

This repository contains a collection of Docker Compose configurations for various services.

## Available Configurations

### Base
These are individual service setups that can be used as building blocks for your projects:

- **Postgres with pgAdmin**: PostgreSQL database with pgAdmin for management.
- **Postgres-pgVector with pgAdmin**: PostgreSQL with pgVector extension and pgAdmin.
- **Kafka with Kafka UI**: Kafka message broker with a management UI.
- **MinIO**: High-performance object storage service.
- **Redis with RedisInsight**: In-memory data store with a management UI.
- **Valkey**: Drop-in Redis replacement managed by the Linux Foundation.
- **RabbitMQ**: Reliable messaging between distributed systems.
- **Qdrant Vector DB**: Optimized for storing and searching high-dimensional vectors.
- **Milvus Vector DB**: Open-source vector database for similarity search.
- **ElasticSearch with Kibana**: Distributed search engine with Kibana for visualization.
- **Grafana with Prometheus**: Metric collection, storage, and visualization.
- **MongoDB with Mongo-Express**: MongoDB paired with a web-based management interface.
- **MySQL with Adminer and phpMyAdmin**: MySQL with Adminer and phpMyAdmin for administration.

### Stacks
These are pre-configured setups combining multiple services for specific use cases:

- **MLflow with MinIO and Postgres**: A stack for managing the machine learning lifecycle, including MinIO for object storage and Postgres for metadata storage.

> **Note**: ElasticAPM integration for ElasticSearch is under development and may not work properly yet. Updates are in progress.

## What next?
- ✅ **MLFlow Stack** added to stacks
- ✅ **Apache Airflow** added to base
- ⬜ **Apache Superset**
- 🚧 **dbt Core**
- ⬜ **Feast**
- ⬜ **Great Expectations**
- ⬜ **BentoML**
- ⬜ **Nvidia Triton**
- ✅ **Valkey** added to base
- ⬜ **Prefect**
- 🚧 **GitLab**

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