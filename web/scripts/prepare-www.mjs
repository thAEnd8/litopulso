// Arma www/index.html juntando las partes de src/ (y revisa que lleguen completas),
// y copia las fuentes para que la app funcione sin internet.
import { mkdirSync, copyFileSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const src = join(root, 'src'), www = join(root, 'www');
mkdirSync(join(www, 'fonts'), { recursive: true });

const sha = b => createHash('sha256').update(b).digest('hex');
const want = Object.fromEntries(readFileSync(join(src, 'index.sha256'), 'utf8').trim().split('\n').map(l => l.split(/\s+/)).map(([h, f]) => [f, h]));
const parts = readdirSync(src).filter(f => f.endsWith('.part')).sort();
let bad = 0;
const bufs = parts.map(f => {
  const b = readFileSync(join(src, f));
  const ok = want[f] === sha(b);
  if (!ok) bad++;
  console.log((ok ? 'ok    ' : 'MAL   ') + f + '  ' + b.length + ' bytes');
  return b;
});
const html = Buffer.concat(bufs);
if (bad || want['index.html'] !== sha(html)) {
  console.error('ERROR: las partes del juego no coinciden con su huella (' + bad + ' parte(s) con diferencias).');
  process.exit(1);
}
writeFileSync(join(www, 'index.html'), html);
console.log('www/index.html listo:', html.length, 'bytes');

for (const [family, weights] of [['chakra-petch', [500, 600, 700]], ['inter', [400, 500, 600]]]) {
  for (const w of weights) {
    const file = `${family}-latin-${w}-normal.woff2`;
    copyFileSync(join(root, 'node_modules', '@fontsource', family, 'files', file), join(www, 'fonts', file));
  }
}
console.log('fuentes copiadas');
