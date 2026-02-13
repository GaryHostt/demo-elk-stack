#!/usr/bin/env bash
# Creates the my-index index with mapping for Mule app search flow.
# Run after Elasticsearch is up: docker compose up -d && ./scripts/create-index.sh

set -e
ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"

echo "Waiting for Elasticsearch at $ES_URL..."
until curl -sf "$ES_URL/_cluster/health" > /dev/null 2>&1; do
  sleep 2
done
echo "Elasticsearch is up."

# Delete index if it exists (idempotent recreate for demo)
curl -s -X DELETE "$ES_URL/my-index" > /dev/null 2>&1 || true

curl -s -X PUT "$ES_URL/my-index" -H "Content-Type: application/json" -d '{
  "mappings": {
    "properties": {
      "service_id": { "type": "keyword" },
      "@timestamp": { "type": "date" },
      "message": { "type": "text" },
      "level": { "type": "keyword" },
      "logger": { "type": "keyword" },
      "thread": { "type": "keyword" },
      "host": { "type": "keyword" }
    }
  }
}'

echo ""
echo "Index my-index created at $ES_URL"
