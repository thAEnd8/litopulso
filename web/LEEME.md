# Litopulso V9.0 (versión HTML como app de Android)

Es el prototipo HTML V8.0 mejorado y empaquetado como app con Capacitor.

- `src/index.NN.part`: el juego (un solo HTML partido en pedazos para poder subirlo). `src/index.sha256` guarda la huella de cada pedazo; si no coincide, la compilación se detiene.
- `scripts/prepare-www.mjs`: junta los pedazos en `www/index.html` y copia las fuentes.
- `scripts/patch-android.mjs`: ajusta el proyecto Android (vertical, ícono, pantalla de carga, versión).
- `res/debug.keystore.b64`: firma fija de prueba, para que cada APK nuevo se instale encima del anterior. No sirve para publicar en Play Store.

Cada vez que algo cambia dentro de `web/`, GitHub Actions compila el APK y lo publica en **Releases**.
Si la compilación falla, se abre un *issue* con el registro del error.

Duelo en línea: los dos teléfonos corren el mismo motor con la misma semilla y solo se mandan la carta elegida, a través de servidores MQTT públicos y gratuitos (broker.emqx.io y broker.hivemq.com). Los mensajes no van cifrados de punta a punta: no mandes datos personales en el nombre.
