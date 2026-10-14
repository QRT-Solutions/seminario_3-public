# Reconstrucción de la vista local

Autoría: QRT Solutions.

La vista `preview.html` incluye React, el renderer visual y los datos simulados;
para abrirla en localhost no hace falta un plugin. El motor `engine.mjs` tampoco
depende de plugins. Este proceso solo es necesario para modificar la vista React.

Con el plugin Data Analytics instalado, localizar su carpeta mediante el catálogo
de skills del agente: es el directorio que contiene `scripts/data-app.mjs` y
`scripts/prepare-data-app.mjs`. No instalar paquetes ni reemplazar sus archivos
protegidos. Ejecutar desde la raíz del repositorio:

```bash
node seminario_3/aplicaciones/kpi-laboratorio/generate-fixture.mjs
node --test seminario_3/aplicaciones/kpi-laboratorio/tests/*.test.mjs
node seminario_3/aplicaciones/kpi-laboratorio/build-preview.mjs /RUTA/AL/PLUGIN/DATA_ANALYTICS
python3 -m http.server 4188 --bind 127.0.0.1 --directory seminario_3/aplicaciones/kpi-laboratorio
```

El build se aloja en `.local/kpi-preview-runtime/`, ignorado por Git. Conserva
la identidad de la vista al reconstruir. Copia únicamente el contenido editable,
compila con el runtime verificado del plugin y exporta un HTML autónomo al
laboratorio. Elimina del entorno de compilación los identificadores de chat.
No lee archivos `.env`, claves de Supabase ni configuración Vercel; no despliega.

Abrir `http://127.0.0.1:4188/preview.html` y revisar todas las tarjetas, gráficos,
fuentes y filtros. Para una edición realizada durante la clase, reconstruir y
recargar la misma pestaña. Si no está disponible el plugin, conservar la vista
compilada y trabajar sobre las fórmulas y su integración con la aplicación existente.

La fuente React usa imports relativos al directorio `src/content/dashboard/` del
runtime; el script los coloca allí sin cambiar el componente. No importar esa
fuente directamente en la aplicación Vercel existente. Para la integración,
reutilizar el motor independiente y adaptar la presentación al framework actual.

[Volver al laboratorio](README.md).
