// Ajusta el proyecto Android que genera `npx cap add android`:
// pantalla vertical, ícono y pantalla de carga propios, versión y Android 7 o más nuevo.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const A = join(root, 'android');
const res = join(A, 'app', 'src', 'main', 'res');
const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
const build = parseInt(process.env.BUILD_NUMBER || '1', 10);
const [maj, min] = pkg.version.split('.').map(Number);

function edit(file, fn) {
  const before = readFileSync(file, 'utf8');
  const after = fn(before);
  if (after === before) throw new Error('Sin cambios en ' + file);
  writeFileSync(file, after);
  console.log('ajustado', file.replace(root + '/', ''));
}
function put(file, text) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, text);
  console.log('creado', file.replace(root + '/', ''));
}

// versión: cada compilación sube el número para que el APK nuevo se instale encima del anterior
edit(join(A, 'app', 'build.gradle'), s => s
  .replace(/versionCode \d+/, `versionCode ${maj * 10000 + min * 1000 + build}`)
  .replace(/versionName "[^"]*"/, `versionName "${maj}.${min}.${build}"`));

edit(join(A, 'variables.gradle'), s => s.replace(/minSdkVersion = \d+/, 'minSdkVersion = 24'));

// solo vertical
edit(join(A, 'app', 'src', 'main', 'AndroidManifest.xml'), s =>
  s.replace('android:name=".MainActivity"', 'android:name=".MainActivity"\n            android:screenOrientation="portrait"'));

// colores y pantalla de carga
put(join(res, 'values', 'lp_colors.xml'), `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="lp_bg">#0e1319</color>
</resources>
`);
edit(join(res, 'values', 'ic_launcher_background.xml'), s => s.replace(/#[0-9A-Fa-f]{6}/, '#0E1319'));
edit(join(res, 'values', 'styles.xml'), s => s
  .replace('<item name="android:background">@drawable/splash</item>', '<item name="android:background">@drawable/lp_splash</item>\n        <item name="android:statusBarColor">@color/lp_bg</item>\n        <item name="android:navigationBarColor">@color/lp_bg</item>')
  .replace('<item name="android:background">@null</item>', '<item name="android:background">@null</item>\n        <item name="android:statusBarColor">@color/lp_bg</item>\n        <item name="android:navigationBarColor">@color/lp_bg</item>'));

// ícono: hexágono con núcleo de energía (vectorial, no necesita imágenes)
const logo = (size, scale) => `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="${size}dp" android:height="${size}dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <group android:pivotX="54" android:pivotY="54" android:scaleX="${scale}" android:scaleY="${scale}">
        <path android:fillColor="#1D2530" android:strokeColor="#3FD9D2" android:strokeWidth="3"
            android:strokeLineJoin="round"
            android:pathData="M54,24 L80,39 L80,69 L54,84 L28,69 L28,39 Z"/>
        <path android:strokeColor="#2A3541" android:strokeWidth="1.5"
            android:pathData="M54,24 L54,36 M80,39 L70,45 M80,69 L70,63 M54,84 L54,72 M28,69 L38,63 M28,39 L38,45"/>
        <path android:fillColor="#3FD9D2" android:fillAlpha="0.22"
            android:pathData="M54,33 L71,54 L54,75 L37,54 Z"/>
        <path android:fillColor="#3FD9D2"
            android:pathData="M54,40 L65,54 L54,68 L43,54 Z"/>
        <path android:fillColor="#E8FFFD"
            android:pathData="M54,47 L59,54 L54,61 L49,54 Z"/>
    </group>
</vector>
`;
put(join(res, 'drawable', 'lp_logo_fg.xml'), logo(108, 0.82));
put(join(res, 'drawable', 'lp_logo.xml'), logo(108, 1));
const adaptive = `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/lp_bg"/>
    <foreground android:drawable="@drawable/lp_logo_fg"/>
</adaptive-icon>
`;
put(join(res, 'mipmap-anydpi-v26', 'ic_launcher.xml'), adaptive);
put(join(res, 'mipmap-anydpi-v26', 'ic_launcher_round.xml'), adaptive);
put(join(res, 'drawable', 'lp_splash.xml'), `<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/lp_bg"/>
    <item android:width="140dp" android:height="140dp" android:gravity="center" android:drawable="@drawable/lp_logo"/>
</layer-list>
`);
console.log('Android listo: versión', `${maj}.${min}.${build}`);
