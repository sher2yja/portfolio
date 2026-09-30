import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

test('diagnostics returns 0 for HTTP 200 and fails for HTTP 503', async () => {
  let status = 200;
  const server = createServer((_, response) => { response.writeHead(status); response.end(); });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const url = `http://127.0.0.1:${server.address().port}/healthz`;
  const run = () => new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [fileURLToPath(new URL('../tools/check-health.mjs', import.meta.url)), url], { stdio: 'ignore' });
    child.once('error', reject);
    child.once('exit', resolve);
  });
  try {
    assert.equal(await run(), 0);
    status = 503;
    assert.equal(await run(), 1);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
