const target = process.argv[2] ?? 'http://127.0.0.1:5678/healthz';

try {
  const response = await fetch(target, { signal: AbortSignal.timeout(5000) });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  console.log(`${target}: healthy`);
} catch (error) {
  console.error(`${target}: ${error.message}`);
  process.exitCode = 1;
}
