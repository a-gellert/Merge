// HTML5 smoke test: serves a bob bundle, runs it in headless Edge/Chrome with a mocked
// Poki SDK, collects console output and takes screenshots over the DevTools protocol.
//
// usage: node tools/web_smoke.js <bundle_dir_with_index.html> <out_dir> [seconds] [autoplay 0|1] [shots 3,8,15] [start_level]
// Bundle first: java -cp <defold.jar> com.dynamo.bob.Bob --root . --platform wasm-web
//   --architectures wasm-web --variant debug --archive --bundle-output <dir> build bundle
const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawn } = require('child_process');

const [, , BUNDLE, OUT, SECS = '20', AUTOPLAY = '1', SHOTS = '3,8,15', START_LEVEL = '0'] = process.argv;
const PORT = 8765;
// optional taps: CLICKS='t:x:y,t:x:y' (seconds, viewport px of the 360x720 page)
const CLICKS = (process.env.CLICKS || '').split(',').filter(Boolean).map(c => c.split(':').map(Number));
const DEBUG_PORT = 9333;
const BROWSER = [
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
].find(p => fs.existsSync(p));

fs.mkdirSync(OUT, { recursive: true });

const POKI_MOCK = `<script>
window.PokiSDK = {
  init: () => Promise.resolve(),
  gameLoadingProgress() {}, gameLoadingFinished() {},
  gameplayStart() { console.log('[poki] gameplayStart'); },
  gameplayStop() { console.log('[poki] gameplayStop'); },
  commercialBreak(cb) { console.log('[poki] commercialBreak'); if (cb) cb(); return Promise.resolve(); },
  rewardedBreak(o) { console.log('[poki] rewardedBreak'); if (o && o.onStart) o.onStart(); return Promise.resolve(true); },
  measure(a, b, c) { console.log('[poki] measure', a, b, c); },
  setDebug() {}, captureError(e) { console.log('[poki] error', e); },
  getURLParam() { return null; }, shareableURL() { return Promise.resolve(''); },
};
window.addEventListener('load', () => setTimeout(() => poki_sdk_loaded(), 50));
</script>`;

function patchedIndex() {
  let html = fs.readFileSync(path.join(BUNDLE, 'index.html'), 'utf8');
  html = html.replace(/<script[^>]*poki-sdk\.js[^>]*><\/script>/, POKI_MOCK);
  const args = ['--config=merge.fresh=1'];
  if (AUTOPLAY === '1') args.push('--config=merge.autoplay=1');
  if (START_LEVEL !== '0') args.push('--config=merge.start_level=' + START_LEVEL);
  html = html.replace('// override ProgressView to create your own loader. See dmloader.js for more details.',
    `CUSTOM_PARAMETERS['engine_arguments'] = ${JSON.stringify(args)};`);
  return html;
}

const MIME = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.json': 'application/json' };
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  if (url === '/' || url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    return res.end(patchedIndex());
  }
  const file = path.join(BUNDLE, url);
  if (!file.startsWith(path.resolve(BUNDLE)) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404); return res.end();
  }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function main() {
  await new Promise(r => server.listen(PORT, r));
  const profile = path.join(require('os').tmpdir(), 'merge_smoke_profile_' + Date.now());
  const browser = spawn(BROWSER, [
    '--headless=new', `--remote-debugging-port=${DEBUG_PORT}`, `--user-data-dir=${profile}`,
    '--window-size=400,800', '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
    '--autoplay-policy=no-user-gesture-required', '--no-first-run', 'about:blank',
  ], { stdio: 'ignore' });

  let targets;
  for (let i = 0; i < 50; i++) {
    try { targets = await (await fetch(`http://127.0.0.1:${DEBUG_PORT}/json`)).json(); break; } catch { await sleep(200); }
  }
  const page = targets.find(t => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise(r => ws.addEventListener('open', r));
  let id = 0;
  const pending = new Map();
  const logs = [];
  ws.addEventListener('message', ev => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) { pending.get(m.id)(m.result); pending.delete(m.id); }
    if (m.method === 'Runtime.consoleAPICalled') {
      logs.push(m.params.args.map(a => a.value !== undefined ? a.value : a.description).join(' '));
    } else if (m.method === 'Runtime.exceptionThrown') {
      logs.push('EXCEPTION ' + JSON.stringify(m.params.exceptionDetails).slice(0, 400));
    }
  });
  const send = (method, params = {}) => new Promise(r => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });

  await send('Runtime.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: 360, height: 720, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: `http://127.0.0.1:${PORT}/` });

  const shots = SHOTS.split(',').map(Number);
  const t0 = Date.now();
  for (const [t, x, y] of CLICKS) {
    setTimeout(async () => {
      // GLFW tracks the cursor from move events, so move first
      await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
      await sleep(50);
      await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
      await sleep(50);
      await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
    }, t * 1000);
  }
  for (const s of shots) {
    while (Date.now() - t0 < s * 1000) await sleep(100);
    const r = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(path.join(OUT, `web_${s}s.png`), Buffer.from(r.data, 'base64'));
  }
  while (Date.now() - t0 < Number(SECS) * 1000) await sleep(200);
  fs.writeFileSync(path.join(OUT, 'web_console.txt'), logs.join('\n'));
  ws.close();
  // Edge/Chrome spawn child processes: kill the whole tree
  spawn('taskkill', ['/PID', String(browser.pid), '/T', '/F'], { stdio: 'ignore' });
  await sleep(500);
  server.close();
  console.log(`console lines: ${logs.length}`);
  const errors = logs.filter(l => /ERROR|EXCEPTION|attempt to|stack traceback/i.test(l));
  console.log(errors.slice(0, 30).join('\n') || 'no errors');
  process.exit(0);
}
main().catch(e => { console.error(e); process.exit(1); });
