#!/usr/bin/env bash
# Creates the my-index index with mapping for Mule app search flow.
# Run after Elasticsearch is up: docker compose up -d && ./scripts/create-index.sh

set -e
ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"
MAX_ATTEMPTS=30
SLEEP=2

echo "Waiting for Elasticsearch at $ES_URL..."
attempt=0
until curl -sf "$ES_URL/_cluster/health" > /dev/null 2>&1; do
  attempt=$((attempt + 1))
  if [[ $attempt -ge $MAX_ATTEMPTS ]]; then
    echo "Could not reach Elasticsearch at $ES_URL after $((MAX_ATTEMPTS * SLEEP))s." >&2
    echo "Is Docker running? Start the stack with: docker compose up -d" >&2
    exit 1
  fi
  sleep $SLEEP
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
