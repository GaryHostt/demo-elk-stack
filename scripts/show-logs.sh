#!/usr/bin/env bash
# Fetch and display recent logs from my-index. Use to verify the ELK stack is working.
# Usage: ./scripts/show-logs.sh [service_id]
#   Optional: service_id filters logs (e.g. service-a). Or set SERVICE_ID env var.

set -e
ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"
INDEX="${ELASTICSEARCH_INDEX:-my-index}"
COUNT="${SHOW_LOGS_COUNT:-15}"
SERVICE_ID="${SERVICE_ID:-$1}"

# Build search body: size, sort, optional term filter on service_id
QUERY='{"size":'"$COUNT"',"sort":[{"@timestamp":"desc"}]}'
if [[ -n "$SERVICE_ID" ]]; then
  QUERY='{"size":'"$COUNT"',"sort":[{"@timestamp":"desc"}],"query":{"term":{"service_id":"'"$SERVICE_ID"'"}}}'
fi

RESPONSE=$(curl -sf -X POST "$ES_URL/$INDEX/_search" -H "Content-Type: application/json" -d "$QUERY" 2>&1) || {
  echo "Error: Could not reach Elasticsearch at $ES_URL (is it running? is $INDEX created?)" >&2
  exit 1
}

# Check for ES error in JSON (e.g. index_not_found)
if echo "$RESPONSE" | grep -q '"error"'; then
  echo "Elasticsearch returned an error:" >&2
  echo "$RESPONSE" | head -c 500 >&2
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  TOTAL=$(echo "$RESPONSE" | jq -r '.hits.total // .hits.total.value // 0')
  echo "Showing up to $COUNT of $TOTAL hits (newest first)"
  echo "---"
  echo "$RESPONSE" | jq -r '.hits.hits[]._source | "\(."@timestamp") [\(.level)] \(.service_id) | \(.message)"'
else
  echo "Tip: install jq for formatted output. Raw response:"
  echo "$RESPONSE" | head -100
fi
