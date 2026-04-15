/**
 * PayU TOKC Generator — Dev Server
 * Start: node server.js  (from this directory)
 * Open:  http://localhost:3001
 *
 * Endpoints:
 *   GET  /                  — serve index.html
 *   GET  /api/config        — return POS_ID from ../.env
 *   POST /api/create-order  { tokToken }  — writes TOK_TOKEN to .env, runs payu_test_recurring_token.sh
 *   POST /api/get-tokc      {}            — runs payu_step3_retrieve_tokc.sh
 */

const http = require('http');
const fs   = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const PORT        = 3001;
const SCRIPTS_DIR = path.join(__dirname, '..');
const ENV_FILE    = path.join(SCRIPTS_DIR, '.env');

// ── .env helpers ─────────────────────────────────────────────────────────────

function readEnvVar(key) {
  if (!fs.existsSync(ENV_FILE)) return null;
  const content = fs.readFileSync(ENV_FILE, 'utf8');
  const m = content.match(new RegExp(`^${key}="?([^"\\n]*)"?`, 'm'));
  return m ? m[1] : null;
}

function writeTokToken(tokToken) {
  if (!fs.existsSync(ENV_FILE)) {
    throw new Error(
      '.env file not found in parent directory.\n' +
      'Please copy .env.example to .env and fill in POS_ID and CLIENT_SECRET.'
    );
  }
  let content = fs.readFileSync(ENV_FILE, 'utf8');
  const line  = `TOK_TOKEN="${tokToken}"`;
  content = /^TOK_TOKEN=/m.test(content)
    ? content.replace(/^TOK_TOKEN=.*/m, line)
    : line + '\n' + content;
  fs.writeFileSync(ENV_FILE, content);
}

// ── Script runner (execFile — no shell injection) ─────────────────────────────

function runScript(scriptName) {
  return new Promise((resolve) => {
    execFile('bash', [scriptName], { cwd: SCRIPTS_DIR, timeout: 30_000 }, (err, stdout, stderr) => {
      resolve({ stdout: stdout || '', stderr: stderr || '' });
    });
  });
}

// ── Output parsers ────────────────────────────────────────────────────────────

function parseCreateOrderOutput(stdout) {
  const orderId     = (stdout.match(/ORDER_ID=(\S+)/)  || [])[1] || null;
  const redirectUri = (stdout.match(/>>> Open this URL in your browser and complete 3DS:\s*\n\s*(\S+)/) || [])[1] || null;
  const bearerToken = (stdout.match(/^TOKEN=(\S+)/m)   || [])[1] || null;
  return { orderId, redirectUri, bearerToken };
}

function parseTokcOutput(stdout) {
  return (stdout.match(/TOKC_[A-Za-z0-9_-]+/) || [])[0] || null;
}

// ── HTTP server ───────────────────────────────────────────────────────────────

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin',  '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') { res.writeHead(200); res.end(); return; }

  const url = req.url.split('?')[0];

  const json = (data, status = 200) => {
    res.writeHead(status, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(data));
  };

  const withBody = (cb) => {
    let raw = '';
    req.on('data', c => raw += c);
    req.on('end', () => {
      try { cb(JSON.parse(raw || '{}')); }
      catch { json({ error: 'Invalid JSON body' }, 400); }
    });
  };

  // ── Static HTML ──────────────────────────────────────────────────────────
  if (req.method === 'GET' && (url === '/' || url === '/index.html')) {
    try {
      const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(html);
    } catch (e) {
      res.writeHead(500); res.end('Could not read index.html: ' + e.message);
    }
    return;
  }

  // ── GET /api/config ───────────────────────────────────────────────────────
  if (req.method === 'GET' && url === '/api/config') {
    json({ posId: readEnvVar('POS_ID') || '511071' });
    return;
  }

  // ── POST /api/create-order ────────────────────────────────────────────────
  if (req.method === 'POST' && url === '/api/create-order') {
    withBody(async ({ tokToken }) => {
      if (!tokToken) { json({ error: 'tokToken is required' }, 400); return; }

      try {
        writeTokToken(tokToken);
      } catch (e) {
        json({ error: e.message }, 500); return;
      }

      console.log('[api] Running payu_test_recurring_token.sh …');
      const { stdout, stderr } = await runScript('payu_test_recurring_token.sh');
      const parsed = parseCreateOrderOutput(stdout);

      if (!parsed.orderId || !parsed.redirectUri) {
        json({ error: 'Could not parse script output', raw: stdout, stderr }, 500);
        return;
      }

      console.log('[api] ORDER_ID:', parsed.orderId);
      json({ ...parsed, log: stdout });
    });
    return;
  }

  // ── POST /api/get-tokc ────────────────────────────────────────────────────
  if (req.method === 'POST' && url === '/api/get-tokc') {
    withBody(async () => {
      console.log('[api] Running payu_step3_retrieve_tokc.sh …');
      const { stdout, stderr } = await runScript('payu_step3_retrieve_tokc.sh');
      const tokc = parseTokcOutput(stdout);

      if (!tokc) {
        json({ error: 'TOKC_ not found — ensure 3DS was completed successfully', raw: stdout, stderr }, 500);
        return;
      }

      console.log('[api] TOKC_:', tokc);
      json({ tokc, log: stdout });
    });
    return;
  }

  res.writeHead(404); res.end('Not found');
});

server.listen(PORT, () => {
  console.log('\n  PayU TOKC Generator');
  console.log('  ─────────────────────────────────────');
  console.log(`  Server:  http://localhost:${PORT}`);
  console.log(`  Scripts: ${SCRIPTS_DIR}`);
  console.log('  ─────────────────────────────────────\n');
});
