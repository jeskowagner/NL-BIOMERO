#!/bin/sh
# Wait for OpenSearch to be ready
until curl -s -o /dev/null -w "%{http_code}" http://opensearch:9200 | grep -q "200"; do
  echo "Waiting for OpenSearch..."
  sleep 5
done

echo "OpenSearch is ready. Creating index template..."

# Create index template with proper mappings
curl -X PUT "http://opensearch:9200/_index_template/biomero-logs-template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["biomero-logs*"],
    "priority": 100,
    "template": {
      "mappings": {
        "properties": {
          "@timestamp": { "type": "date" },
          "service": { "type": "keyword" },
          "file": { "type": "keyword" },
          "level": { "type": "keyword" },
          "job": { "type": "keyword" },
          "logger": { "type": "keyword" },
          "pid": { "type": "keyword" },
          "thread": { "type": "keyword" },
          "message": { "type": "text" }
        }
      },
      "settings": {
        "number_of_shards": 1,
        "number_of_replicas": 0
      }
    }
  }'

echo ""
echo "Index template created successfully."
