// Arma www/index.html juntando las partes de src/ (y revisa que lleguen completas),
// le aplica los parches de versiones nuevas (src/*.patch.NN) y copia las fuentes
// para que la app funcione sin internet.
import { mkdirSync, copyFileSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = join(root, 'src'), www = join(root, 'www');
mkdirSync(join(www, 'fonts'), { recursive: true });

const sha = b => createHash('sha256').update(b).digest('hex');
const hashes = f => Object.fromEntries(readFileSync(join(src, f), 'utf8').trim().split('\n').map(l => l.split(/\s+/)).map(([h, n]) => [n, h]));
const want = hashes('index.sha256');
const parts = readdirSync(src).filter(f => f.endsWith('.part')).sort();
let bad = 0;
const bufs = parts.map(f => {
  const b = readFileSync(join(src, f));
  const ok = want[f] === sha(b);
  if (!ok) bad++;
  console.log((ok ? 'ok    ' : 'MAL   ') + f + '  ' + b.length + ' bytes');
  return b;
});
let html = Buffer.concat(bufs).toString('utf8');
if (bad || want['index.html'] !== sha(html)) {
  console.error('ERROR: las partes del juego no coinciden con su huella (' + bad + ' parte(s) con diferencias).');
  process.exit(1);
}

// Parche: líneas "@@ desde hasta n" cambian las líneas [desde, hasta) del original por las n líneas siguientes.
function applyPatch(text, patch) {
  const a = text.split('\n'), p = patch.split('\n'), out = [];
  let pos = 0, i = 0;
  while (i < p.length) {
    const m = /^@@ (\d+) (\d+) (\d+)$/.exec(p[i]);
    if (!m) { if (p[i] === '' && i === p.length - 1) break; throw new Error('parche mal formado en la línea ' + (i + 1)); }
    const i1 = +m[1], i2 = +m[2], n = +m[3];
    if (i1 < pos || i2 < i1 || i2 > a.length) throw new Error('parche fuera de orden en la línea ' + (i + 1));
    for (; pos < i1; pos++) out.push(a[pos]);
    for (let k = 0; k < n; k++) out.push(p[i + 1 + k]);
    pos = i2; i += 1 + n;
  }
  for (; pos < a.length; pos++) out.push(a[pos]);
  return out.join('\n');
}
const names = [...new Set(readdirSync(src).filter(f => /\.patch\.\d+$/.test(f)).map(f => f.replace(/\.\d+$/, '')))].sort();
for (const name of names) {
  const pp = readdirSync(src).filter(f => f.startsWith(name + '.')).sort();
  const ph = hashes(name.replace(/\.patch$/, '') + '.sha256');
  let patch = '';
  for (const f of pp) {
    const b = readFileSync(join(src, f));
    if (ph[f] !== sha(b)) { console.error('ERROR: ' + f + ' no coincide con su huella.'); process.exit(1); }
    patch += b.toString('utf8');
  }
  html = applyPatch(html, patch);
  if (ph['index.html'] !== sha(html)) { console.error('ERROR: después de ' + name + ' el juego no coincide con su huella.'); process.exit(1); }
  console.log('parche ' + name + ' aplicado (' + pp.length + ' partes)');
}
writeFileSync(join(www, 'index.html'), html);
console.log('www/index.html listo:', Buffer.byteLength(html), 'bytes');

for (const [family, weights] of [['chakra-petch', [500, 600, 700]], ['inter', [400, 500, 600]]]) {
  for (const w of weights) {
    const file = `${family}-latin-${w}-normal.woff2`;
    copyFileSync(join(root, 'node_modules', '@fontsource', family, 'files', file), join(www, 'fonts', file));
  }
}
console.log('fuentes copiadas');
