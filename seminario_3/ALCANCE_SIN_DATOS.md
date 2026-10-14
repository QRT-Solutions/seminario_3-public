# Alcance de Entrega Pública Sin Datos de Transacciones

> **Autor Canónico:** QRT Solutions  
> **Ámbito:** Repositorio Institucional y Laboratorio Cuantitativo `seminario_3-public`  
> **Estado:** Directiva de Alcance y Matriz de Saneamiento (Seminario 2 como Base)  
> **Fecha:** 13 de Octubre de 2026  

---

## 1. Directiva Prioritaria: Seminario 2 como Base y Política de Cero Datos

Por directiva del propietario del proyecto, se establece el marco normativo vinculante para la preparación de la entrega pública:

1. **Seminario 2 se conserva como la BASE integral de este repositorio:**  
   Queda **formalmente superada** cualquier propuesta de excluir en bloque la presentación masterclass, el catálogo de 17 estrategias cuantitativas, la biblioteca de conocimiento o los módulos heredados. Seminario 2 constituye el cimiento metodológico, técnico y pedagógico del espacio de trabajo.
2. **Prohibición estricta de datos de transacciones:**  
   Se mantiene la prohibición absoluta de distribuir datos de transacciones (ni operaciones reales, ni sintéticas, ni simuladas) y resultados medidos de cuentas.
3. **El estado del «supervisor» no bloquea esta revisión:**  
   La definición final del componente supervisor (sea dashboard web, bot en Telegram o servicio externo) permanece pendiente, pero no bloquea la revisión, consolidación y saneamiento de la base de Seminario 2.
4. **Diferenciación conceptual rigurosa:**
   - **Parámetros vs. Datasets:** Constantes de trading (períodos EMA, multiplicadores ATR, lookback, lotajes, límites de tiempo-stop), fechas de vigencia de contratos, IDs canónicos y listas de símbolos **son parámetros de diseño y código**, no datasets transaccionales.
   - **Datos de Mercado OHLC:** Las cotizaciones históricas de mercado (velas) **no son registros de transacciones**. La política institucional es no distribuir datasets de mercado por defecto, dejando su eventual incorporación sujeta a una decisión separada.
   - **Código que procesa datos privados:** Todo el código diseñado para recibir, agregar o graficar operaciones privadas del alumno en tiempo de ejecución se conserva íntegramente.
   - **Lógica de Ingesta SQL:** Las instrucciones `INSERT` presentes dentro de funciones y triggers de ingesta (en `esquema_telemetria.sql`, etc.) corresponden a código e infraestructura de absorción de telemetría, no a datos semilla de operaciones docentes.
   - **Edge Functions:** Se conservan para el canal conectado, sujetas a revisión técnica individual antes de declarar su estado final.
   - **Evidencia Técnica de Compilación:** Archivos como `compile-evidence.json` constituyen diagnósticos técnicos de la plataforma MQL5 (cero errores, cero advertencias), no datos transaccionales; se conservan saneando posibles metadatos del entorno local.

---

## 2. Matriz de Clasificación del Repositorio

A continuación se define la taxonomía autoritativa de cada componente del repositorio bajo tres criterios operativos: **CONSERVAR**, **CONSERVAR SANEANDO** o **EXCLUIR SOLO DATOS**.

| Módulo / Componente | Elementos Específicos | Clasificación | Criterio de Saneamiento / Decisión |
| :--- | :--- | :--- | :--- |
| **Core y Herramientas Sem2** | `src/seminario_lab/`, `pyproject.toml`, `uv.lock`, CI workflows, `tools/` (`check_links.py`, `docs_hook.py`, etc.) | **CONSERVAR** | Infraestructura de verificación, integridad y CLI institucional. No contiene datos transaccionales. |
| **Estrategias y Contratos Sem2** | Fuentes MQL5 POO, TradingView Pine Script v6, plantillas en `templates/`, esquemas JSON y validador `src/seminario_lab/validation.py` | **CONSERVAR** | Código algorítmico, lógica matemática y contratos formales. Las constantes de trading son especificaciones, no transacciones. |
| **Narrativas de Backtest del Catálogo** | Especificaciones JSON y Factsheets (`DONCHIAN_DBL v1.1`, `ORB_MOM v1.1`, `GOLD_SMA_CROSS v1.1`) | **CONSERVAR SANEANDO** | Sanear claims y referencias a reportes previos o resultados medidos. Las hipótesis explícitas y targets se conservan, pero no deben presentarse como métricas empíricas garantizadas. No tocar parámetros ni código. |
| **Masterclass (Estructura y Conceptos)** | Navegación, `masterclass/styles.css`, `masterclass/QRT-LOGO.png`, librerías vendor (`chartjs`, `lucide`), licencias, conceptos puros (`xyzCases` en `app.js:218`, `exitData` en `app.js:379`) y esquemas vectoriales SVG (`index.html:1049-1230`) | **CONSERVAR** | Estructura pedagógica, estilos y dibujos conceptuales (no son datos de mercado ni transacciones). |
| **Masterclass (Gráficos y Muestras Didácticas)** | `masterclass/app.js` (conteos demo:293–338, Monte Carlo:354–373, heatmaps:444–485, conteos condición:511, frecuencias MAE:572, curva holding:599) e `index.html` (atributos `data-notes`, calendario:802, distribuciones MAE/MFE:1233–1366, tablas IS/OOS:1767–1900) | **CONSERVAR SANEANDO** | Requieren saneamiento hacia una UI neutra o configurable con textos, ejes, fórmulas y guion sincronizado. En `app.js:541`, `data: []` se repuebla en runtime al invocar `runMonteCarlo(2)` en línea 553, por lo que vaciar arrays estáticos no basta. Precios esquemáticos, señales hipotéticas y simuladores didácticos son decisiones de alcance para el propietario. |
| **Tests Estructurales Sem2** | `tests/test_presentation.py` (recursos, accesibilidad, licencias), `tests/test_registry.py:97` (prueba cabecera CSV temporal sin trades) y fixtures de schema, rutas y credenciales sintéticas | **CONSERVAR** | Pruebas de integridad del sistema. Los fixtures de esquema, rutas o tokens simulados no son transacciones y se mantienen. |
| **Suites Node.js y SQL con Fixtures Transaccionales** | `seminario_3/aplicaciones/web/tests/*.test.mjs`, `verificar_dashboard_kpis.sql`, `verificar_dashboard_distribuciones.sql`, `verificar_protecciones.sql`, `verificar_dashboard_editor.sql` | **CONSERVAR SANEANDO** | Se conserva la lógica no transaccional de los tests. Se propone sanear selectivamente los fixtures con transacciones o diseñar tests en frío (cold-start) antes de distribuir. |
| **Bibliografía y Corpus de Conocimiento** | Índices, citas, material formativo, `base_de_conocimientos/` (50 libros), `MT5/knowledge/` (4 manuales técnicos + índice) y metadatos de integridad (`docs/knowledge-import.json`, `docs/content-manifest.json`) | **CONSERVAR con REVISIÓN INDEPENDIENTE** | No se excluyen por pertenecer a Sem2. Se conservan sujetos a revisión independiente por derechos de autor y licencias de terceros, sin asumir autorizaciones legales definitivas ni borrar el corpus. Reconciliación documental pendiente: alinear la nota de `docs/references.md:13` con el corpus importado. Los metadatos de hash se conservan. |
| **Infraestructura MT5 / Supabase / Telegram** | Exportador MT5 v3.40 (`MT5_Telemetry_Exporter_Universal.mq5` con `InpEnableKillSwitch=false`), 12 scripts DDL SQL (`esquema_telemetria.sql`, etc.), scripts de verificación de esquema (`verificar_receptor.sql`, etc.), Edge Functions (`mt5-telemetry` con `x-mt5-token`, `mt5-telegram`, `editor`) | **CONSERVAR** | Infraestructura de transmisión conectada para datos privados del alumno. Revisión técnica individual de Edge Functions pendiente. |
| **Laboratorio KPI (Código)** | `seminario_3/aplicaciones/kpi-laboratorio/engine.mjs` y `DashboardContent.jsx` | **CONSERVAR** | Código fuente reutilizable de cálculo y componentes visuales. No se excluye automáticamente por ubicación de carpeta. |
| **Laboratorio KPI (Datos Embebidos)** | `seminario_3/aplicaciones/kpi-laboratorio/fixture.json` y `preview.html` (con bundle de transacciones incrustadas) | **EXCLUIR SOLO DATOS** | Contienen `queries.trades.rows` y `queries.daily.rows`. Quedan excluidos del paquete distribuible exclusivamente en cuanto a sus datos transaccionales almacenados. |
| **Generador de Fixture KPI** | `seminario_3/aplicaciones/kpi-laboratorio/generate-fixture.mjs` | **DECISIÓN SEPARADA** | Genera operaciones sintéticas. Se propone dejarlo fuera de la entrega sin datos por su función específica, distinguiendo el código fuente del dataset almacenado. |
| **Evidencias y Bitácoras Docentes** | `seminario_3/ESTADO.md`, `seminario_3/supabase/BITACORA.md`, `VERIFICACION.md`, `AYUDA_MEMORIA.md`, `EDICION.md` | **CONSERVAR SANEANDO** | Se conserva la estructura técnica, guías y bitácoras; se sanean los relatos, capturas y cifras resultantes de las pruebas con la cuenta demo docente. |
| **Evidencia de Compilación de Estrategias** | `MT5/evidencia/STRAT-20261008-BREAKOUT3_LONG-M5-v1.0/compile-evidence.json` | **CONSERVAR SANEANDO** | Evidencia técnica de compilación de la plataforma (0 errores/0 advertencias). Se conserva saneando posibles metadatos del entorno local. |
| **Archivos Privados e Ignorados** | Variables de entorno reales (`.env`, `.env.*`), logs locales (`*.log`), binarios compilados (`*.ex5`), `.local/` | **EXCLUIR** | Archivos privados y específicos del entorno de desarrollo según `.gitignore`. |

---

## 3. Hoja de Ruta de Saneamiento Específico

### 3.1. Masterclass: Puntos de Intervención Estática
- **Código a sanear puntualmente en `masterclass/app.js`:**
  - L293–338: Conteos de demostración docente.
  - L354–373: Función `runMonteCarlo` con serie sintética.
  - L444–485: Generación de heatmaps de prueba.
  - L511: Conteos de muestra en `conditionChart`.
  - L572: Frecuencias MAE en `maeChart`.
  - L599: Curva holding period en `holdingChart`.
  - *Comportamiento en runtime:* En L541 la propiedad `data: []` está inicialmente vacía, pero se repuebla automáticamente al ejecutarse `runMonteCarlo(2)` en L553/560. Por tanto, vaciar arrays estáticos no es suficiente; se requerirá desacoplar el invocador en tiempo de ejecución.
- **Contenido a sanear en `masterclass/index.html`:**
  - Atributos `data-notes`: Conservan cifras y relatos de demostración oculta.
  - L802–835: Calendario didáctico con señales y resultados hipotéticos de muestra.
  - L1233–1366: Gráficos de dispersión MAE/MFE de ejemplo.
  - L1767–1900: Tablas comparativas In-Sample vs. Out-of-Sample con cifras de muestra.
- **Decisiones de alcance:** Los precios esquemáticos, señales hipotéticas y simuladores didácticos representan decisiones de diseño pedagógico para el propietario y no deben ser eliminados de forma automática. Se propone estructurar una UI neutra/configurable con textos, fórmulas, ejes y guion sincronizado (sin implementar hoy).

### 3.2. Catálogo de Estrategias: Saneamiento de Narrativas de Backtest
- El catálogo se conserva íntegro en código MQL5, Pine Script y especificaciones JSON. `src/seminario_lab/validation.py:82-100` compara hashes de código y `tools/docs_hook.py:53-74` sincroniza la documentación.
- **Intervenciones requeridas en narrativas (sin alterar parámetros de trading):**
  - `DONCHIAN_DBL v1.1` specification (L8): Retirar referencias a reportes externos ausentes.
  - `ORB_MOM v1.1` specification (L7–8, 39) y factsheet (L9): Retirar descripciones narrativas de resultados previos.
  - `GOLD_SMA_CROSS v1.1` specification (L7) y factsheet (L9): Separar claramente las hipótesis y objetivos de diseño frente a afirmaciones de resultados medidos. Las hipótesis explícitas son válidas; las afirmaciones de desempeño empírico pasado deben deslindarse.

### 3.3. Pruebas Unitarias y Fixtures
- `tests/test_presentation.py` comprueba recursos, licencias, accesibilidad y ausencia de datasets externos (no valida arrays en código JS).
- `tests/test_registry.py:97` genera una cabecera CSV temporal para validar rutas prohibidas, sin transacciones.
- Los fixtures de schema, rutas y credenciales sintéticas son válidos y se conservan. Las pruebas con operaciones de trading o retornos simulados se sanearán selectivamente antes de la distribución pública.

### 3.4. Bibliografía y Derechos de Autor
- `base_de_conocimientos/` (50 libros comerciales) y `MT5/knowledge/` (4 manuales técnicos + índice) se conservan en el repositorio base.
- Se gestionarán mediante una **revisión independiente de procedencia y licencias de terceros**, sin asumir autorizaciones legales definitivas ni borrar el corpus.
- Reconciliación documental pendiente: alinear la declaración de `docs/references.md:13` (que indica que los textos completos no se redistribuyen) con la existencia del corpus importado.
- Los metadatos de procedencia e integridad (`docs/knowledge-import.json`, `docs/content-manifest.json`) contienen hashes de integridad, no datos de trading; deben conservarse intactos.

---

## 4. Estado de Git Observado en el Entorno Local

1. **Ramas y Referencias Locales:**
   - La rama local `main` se encuentra 1 commit por delante (`HEAD` 5246664) de `origin/main` (2416eee), el cual apunta al estado consolidado de Seminario 2.
   - El directorio `seminario_3/` no está rastreado (`??`) y no figura en los commits de las referencias locales consultadas.
   - Seminario 2 sí cuenta con un historial de commits en Git. Por tanto, no se realizan afirmaciones de «riesgo histórico cero».
2. **Archivos Rastreados e Ignorados:**
   - Las inspecciones en el árbol rastreado y en el historial local no detectaron datasets masivos (`.csv`, `.xlsx`, `.parquet`, `.ipynb`), salvo recursos gráficos como el logotipo PNG.
   - Esto describe el **alcance observado** en las referencias inspeccionadas y no certifica la ausencia total de datos incrustados o de archivos ignorados localmente.
3. **Propuesta para la Publicación Futura:**
   - Una rama nueva ordinaria de Git **no elimina el historial previo**.
   - Para la distribución pública final, se mantiene como propuesta de diseño la preparación de una carpeta o repositorio independiente exportado desde cero sin arrastrar el directorio `.git` actual. No se ha inicializado ningún repositorio nuevo ni se han ejecutado operaciones destructivas.

---

## 5. Próximos Pasos para el Propietario

1. **Aclaración del «Supervisor»:** Confirmar la naturaleza del componente supervisor (frontend web, bot en Telegram o servicio externo) cuando corresponda; este punto no bloquea el saneamiento del repositorio base.
2. **Aprobación de la Matriz de Saneamiento:** Validar la clasificación de la Sección 2 para proceder en fases posteriores con el saneamiento puntual de textos y narrativas.
