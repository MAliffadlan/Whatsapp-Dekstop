'use strict';
// Executes the real injected init script against a WhatsApp-Web-shaped DOM and
// asserts the invariant that no single failure locks the user out of Settings.
//
// Usage: node init_script_harness.js <path-to-init-script.js>
// Exits 0 on pass. Prints a JSON {"skipped": "..."} line and exits 0 when jsdom
// is unavailable, so the Go test can skip instead of failing.
const fs = require('fs');

let JSDOM, VirtualConsole;
try {
  ({ JSDOM, VirtualConsole } = require('jsdom'));
} catch (e) {
  console.log(JSON.stringify({ skipped: 'jsdom is not installed in this environment' }));
  process.exit(0);
}

const scriptPath = process.argv[2];
if (!scriptPath) {
  console.log(JSON.stringify({ skipped: 'no script path given' }));
  process.exit(0);
}
const script = fs.readFileSync(scriptPath, 'utf8');

const HEAD = '<!doctype html><html><head></head><body><div id="app"><div id="side"></div></div></body></html>';
const BRIDGES = ['getDownloadDirNative', 'openDownloadDirNative', 'sendNativeNotification', 'openExternalLink'];

function run(transform, envMutate) {
  const src = transform ? transform(script) : script;
  const dom = new JSDOM(HEAD, {
    runScripts: 'outside-only',
    pretendToBeVisual: true,
    url: 'https://web.whatsapp.com/',
    virtualConsole: new VirtualConsole(),
  });
  const { window } = dom;
  for (const n of BRIDGES) window[n] = () => Promise.resolve('');
  if (envMutate) envMutate(window);

  let threw = null;
  try { window.eval(src); } catch (e) { threw = e; }

  const doc = window.document;
  const entryPoints = ['wa-emergency-settings-btn', 'wa-settings-fallback-btn', 'wa-toolbar-settings-btn']
    .filter((id) => doc.getElementById(id));

  window.dispatchEvent(new window.KeyboardEvent('keydown', { key: ',', ctrlKey: true, bubbles: true, cancelable: true }));
  const opened = doc.getElementById('wa-settings-overlay') || doc.getElementById('wa-recovery-overlay');

  return { threw: threw ? String(threw).split('\n')[0] : 'no', entryPoints, opened: opened ? opened.id : null };
}

const cases = [
  ['baseline', null, null, script],
  ['early module failure', (s) => s.replace('\t\t// Emulate window.chrome',
    '\t\tthrow new Error("injected early failure");\n\t\t// Emulate window.chrome'), null, script],
  ['modal failure', (s) => s.replace('window.showSettingsModal = function() {',
    "window.showSettingsModal = function() { throw new Error('injected modal failure');"), null, script],
  ['localStorage denied', null,
    (w) => Object.defineProperty(w, 'localStorage', {
      get() { throw new Error('SecurityError: access denied'); }, configurable: true,
    }), script],
];

let failures = 0;
for (const [label, transform, envMutate] of cases) {
  const r = run(transform, envMutate);
  const ok = r.entryPoints.length > 0 && !!r.opened;
  if (!ok) failures++;
  console.log(`${ok ? 'GREEN' : 'RED  '}  ${label.padEnd(22)} entry=${r.entryPoints.join(',') || 'NONE'} opened=${r.opened || 'NOTHING'} uncaught=${r.threw}`);
}

if (failures) {
  console.log(`\nFAIL: ${failures} scenario(s) leave the user with no Settings entry point.`);
  process.exit(1);
}
console.log('\nPASS: no single injected-script failure removes the Settings entry point or the Ctrl+, shortcut.');
process.exit(0);
