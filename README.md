# Local ELK Stack for Mule App Demo

Minimal local Elasticsearch + Kibana stack with random logs, for demos where an external Mule app calls Elasticsearch (e.g. `elk-search-logic-flow` and `anomaly-status-flow`).

## Quick start

1. **Start the stack**
   ```bash
   docker compose up -d
   ```
   Wait until Elasticsearch is healthy (about 30–60 seconds).

2. **Create the index**
   ```bash
   ./scripts/create-index.sh
   ```

3. **Generate random logs**
   ```bash
   npm install
   npm run generate-logs
   ```

4. **Optional:** Open Kibana at [http://localhost:5601](http://localhost:5601) and create an index pattern for `my-index`, then use Discover to view logs.

## Connecting your Mule app

### Elasticsearch base URL

- **Mule app on host:** use `http://localhost:9200`
- **Mule app in Docker:** use `http://host.docker.internal:9200` (macOS/Windows) or the host IP on Linux.

Point your Mule **HTTP Request config** (`Elasticsearch_Request_Config`) at this base URL (no path).

### Index name

The default index is `my-index`. If your app uses a different name, set the Mule property:

- `elasticsearch.index` = `my-index` (or your index name)

### Search flow (`elk-search-logic-flow`)

- The flow expects a payload with **`service_id`** (required). It builds an Elasticsearch query (e.g. via `queryEngineToES.dwl`) and sends it as `POST /{index}/_search`.
- Example payload shape: `{"service_id": "service-a"}` (plus any other fields your DataWeave script needs).
- Documents in `my-index` include `service_id` with values such as `service-a`, `service-b`, `service-c`, `mule-service`, `api-gateway`. Use one of these when calling the flow to get hits.

### Anomaly flow (`anomaly-status-flow`)

- This flow calls **`POST /_ml/anomaly_detectors/{job_id}/_results`** and expects a payload with **`job_id`**.
- Creating and running ML anomaly detection jobs usually requires an Elasticsearch license that includes ML (e.g. trial or paid). This local stack does **not** create an ML job.
- For a **search-only demo**, you can skip the anomaly flow or mock it. To use the anomaly flow, you would need to create an anomaly detection job in Elasticsearch and ensure your cluster has ML enabled and an appropriate license.

## Order of operations (summary)

1. `docker compose up -d` — start Elasticsearch and Kibana.
2. `./scripts/create-index.sh` — create `my-index` with the right mapping.
3. `npm run generate-logs` — seed `my-index` with random logs.
4. In the Mule app: set `Elasticsearch_Request_Config` to `http://localhost:9200` and `elasticsearch.index` to `my-index` (if needed).
5. Call the Mule **elk-search-logic-flow** with a payload that includes `service_id` (e.g. `{"service_id": "service-a"}`) and confirm results in the response or in Kibana Discover.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ELASTICSEARCH_URL` | `http://localhost:9200` | Used by `create-index.sh` and `generate-logs.js`. |
| `ELASTICSEARCH_INDEX` | `my-index` | Index used by `generate-logs.js`. |
| `LOG_COUNT` | `300` | Number of log documents to generate. |

## Index mapping

`my-index` is created with:

- `service_id` (keyword)
- `@timestamp` (date)
- `message` (text)
- `level` (keyword)
- `logger` (keyword)
- `thread` (keyword)
- `host` (keyword)

## Stopping the stack

```bash
docker compose down
```

Data is stored in a Docker volume (`elasticsearch-data`). Use `docker compose down -v` to remove it and start with an empty index next time.
