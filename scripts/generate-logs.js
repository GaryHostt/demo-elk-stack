#!/usr/bin/env node
/**
 * Bulk-index random log documents into my-index for Mule app search demo.
 * Run after ES is up and create-index.sh has been run: npm run generate-logs
 */

const { Client } = require('@elastic/elasticsearch');

const ES_URL = process.env.ELASTICSEARCH_URL || 'http://localhost:9200';
const INDEX = process.env.ELASTICSEARCH_INDEX || 'my-index';
const COUNT = parseInt(process.env.LOG_COUNT || '300', 10);

const SERVICE_IDS = ['service-a', 'service-b', 'service-c', 'mule-service', 'api-gateway'];
const LEVELS = ['INFO', 'WARN', 'ERROR'];
const LOGGERS = ['com.mule.flow', 'org.mule.engine', 'http.request', 'scheduler', 'connector'];
const MESSAGES = [
  'Request received for path /api/orders',
  'Transaction completed successfully',
  'Connection timeout to downstream service',
  'Cache miss for key %s',
  'Validation failed: missing required field',
  'Rate limit approaching threshold',
  'Anomaly score above threshold',
  'Job scheduled for execution',
  'HTTP 502 from upstream',
  'Retry attempt %d of 3',
  'Session created for user',
  'Elasticsearch query executed',
  'Token optimizer applied',
  'PII redaction completed',
];

function randomChoice(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomPastDate(withinDays = 7) {
  const now = Date.now();
  const past = now - withinDays * 24 * 60 * 60 * 1000;
  return new Date(past + Math.random() * (now - past)).toISOString();
}

function buildDoc() {
  const msg = randomChoice(MESSAGES);
  return {
    service_id: randomChoice(SERVICE_IDS),
    '@timestamp': randomPastDate(),
    message: msg.includes('%') ? msg.replace(/%[sd]/, Math.floor(Math.random() * 10)) : msg,
    level: randomChoice(LEVELS),
    logger: randomChoice(LOGGERS),
    thread: `thread-${Math.floor(Math.random() * 8)}`,
    host: `host-${Math.floor(Math.random() * 4)}`,
  };
}

async function main() {
  const client = new Client({ node: ES_URL });

  const body = [];
  for (let i = 0; i < COUNT; i++) {
    body.push({ index: { _index: INDEX } });
    body.push(buildDoc());
  }

  const result = await client.bulk({ refresh: true, body });
  if (result.errors) {
    const failed = result.items.filter((i) => i.index?.error);
    console.error('Some documents failed:', failed.length, failed.slice(0, 3));
    process.exit(1);
  }
  console.log(`Indexed ${COUNT} log documents into ${INDEX} at ${ES_URL}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
