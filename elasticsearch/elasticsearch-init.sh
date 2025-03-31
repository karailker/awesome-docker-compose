#!/bin/bash

# Wait for Elasticsearch to be ready
until curl -u elastic:$ELASTIC_PASSWORD -s -XGET "http://elasticsearch:9200" > /dev/null 2>&1; do
  echo "Waiting for Elasticsearch to be ready..."
  sleep 5
done

# Create a service account
curl -u elastic:$ELASTIC_PASSWORD -X POST "http://elasticsearch:9200/_security/service/elastic-kibana-service-account" -H 'Content-Type: application/json' -d'
{
  "password" : "kibanaservicepassword"
}
'

# Assign the "kibana_system" role to the service account
curl -u elastic:$ELASTIC_PASSWORD -X POST "http://elasticsearch:9200/_security/role/kibana_system" -H 'Content-Type: application/json' -d'
{
  "cluster": ["all"],
  "index": [
    {
      "names": [ "*" ],
      "privileges": ["read", "write"]
    }
  ]
}
'

curl -u elastic:$ELASTIC_PASSWORD -X POST "http://elasticsearch:9200/_security/service/elastic-kibana-service-account/_assign" -H 'Content-Type: application/json' -d'
{
  "roles": ["kibana_system"]
}
'

echo "Service account and role assigned successfully."
