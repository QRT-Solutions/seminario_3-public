# Resumen Sanitizado de Preparación Pública — 13 de Octubre de 2026

> **Autoría institucional:** QRT Solutions  
> **Ámbito:** Registro de verificaciones, comandos ejecutados, códigos de salida y estado local previo a la entrega pública del Seminario 3 por el propietario.  
> **Ubicación de evidencia técnica detallada (privada):** `.local/preparacion-publica-20261013/` (excluido de Git).

---

## 1. Alcance de la tarea ejecutada

Se preparó localmente el repositorio `seminario_3-public` para que el titular del proyecto lo publique posteriormente en GitHub y lo distribuya a los alumnos:
1. **README raíz conciso y estructurado:** Propósito del Seminario 3, selección clara de dos rutas (Introductoria sin credenciales vs Técnica completa), tabla de requisitos por nivel, primer ejercicio con `preview.html`, mapa de carpetas y estado honesto de la versión (v3.40).
2. **Nueva guía `seminario_3/guias/EMPIEZA_AQUI.md`:** Diseñada para alumnos sin conocimientos de programación, con instrucciones paso a paso para macOS y Windows, alternativa con servidor local (`--bind 127.0.0.1`), distinción estricta entre la muestra simulada (48 operaciones analizables, una excluida y 40 retornos diarios ficticios) frente a datos reales, y tabla de requisitos.
3. **Sincronización técnica y documental:** Actualización de `docs/architecture.md` reflejando las tecnologías operativas reales (Vanilla HTML/CSS/JS + Chart.js en la web, React en laboratorio de KPIs, 12 referencias SQL ordenadas y suites de tests Node.js). Sincronización del exportador a **v3.40** en `README.md`, `README.en.md` y `CONFIGURACION.md`. Nueva entrada de bitácora en `seminario_3/supabase/BITACORA.md` sin reescribir la historia previa.
4. **Refuerzo de `seminario_3/ENTREGA.md`:** Checklist de contenido seleccionable, aislamiento riguroso de archivos privados (`.local/`, `.env.local`, `.mcp.json`, etc.) y advertencia sobre derechos de autor en `base_de_conocimientos/` (50 libros de trading comercial donde no aplica MIT) y manuales en `MT5/knowledge/`, recordando que `.gitignore` no desindexa archivos ya rastreados en Git.
5. **Resolución diagnóstica de BREAKOUT3:** Corrección en el factsheet de la referencia local a `compile.log` mediante enlace canónico a `compile-evidence.json`, evitando enlaces rotos en MkDocs. Documentada la incorporación al catálogo y CI para una segunda etapa.

---

## 2. Matriz de verificación técnica ejecutada

Todas las pruebas se ejecutaron sobre runtimes y dependencias locales ya existentes, sin mutaciones de nube, sin llamadas a MetaTrader 5 y sin tráfico de red externo:

| Comprobación | Comando exacto ejecutado | Exit Code | Resultado medido |
|---|---|:---:|---|
| **Entorno base del catálogo** | `uv run --locked seminario doctor` | `0` | Listo: 17 estrategias válidas, Python 3.12.13, credenciales no requeridas. |
| **Integridad del catálogo** | `uv run --locked seminario verify` | `0` | 17 estrategias verificadas, 0 errores, esquemas y contratos íntegros. |
| **Suite offline MT5 Operator** | `uv run --locked python .agents/skills/mt5-platform-operator/tests/run_offline.py` | `0` | 63 pruebas pasadas, 0 falladas (contratos, esquemas y ExecutionEvidence). |
| **Verificación de enlaces internos** | `python3 tools/check_links.py` | `0` | 0 fallos de enlaces; 336 destinos externos no solicitados. |
| **Construcción estática MkDocs** | `uv run --locked mkdocs build --strict` | `0` | Construcción limpia en 0,64 s; 0 advertencias y 0 errores en modo estricto. |
| **Tests unitarios web** | `npm test --prefix seminario_3/aplicaciones/web` | `0` | 13 pruebas pasadas, 0 falladas (métricas, filtros, gráficos, estados). |
| **Tests Edge Function telemetría** | `node --test seminario_3/supabase/functions/mt5-telemetry/*.test.mjs` | `0` | 13 pruebas pasadas, 0 falladas (autenticación, validación de esquemas, colas). |
| **Tests Edge Function Telegram** | `node --test seminario_3/supabase/functions/mt5-telegram/*.test.mjs` | `0` | 18 pruebas pasadas, 0 falladas (webhook, vinculación, respuestas directas, OTP). |
| **Tests Edge Function editor web** | `node --test seminario_3/supabase/functions/mt5-dashboard-editor/*.test.mjs` | `0` | 6 pruebas pasadas, 0 falladas (CORS, tokens de un uso, sesiones en memoria). |
| **Tests motor de diez KPIs** | `node --test seminario_3/aplicaciones/kpi-laboratorio/tests/*.test.mjs` | `0` | 8 pruebas pasadas, 0 falladas (fórmulas, rachas, ratios, anualización). |
| **Generador offline de credencial** | `python3 -m unittest seminario_3/pruebas/test_credencial.py` | `0` | 3 pruebas pasadas, 0 falladas (archivos privados 0600, hash SHA256, rechazo público). |
| **Escáner de publicación (árbol)** | `PYTHONPATH=src python3 -m seminario_lab.publication --no-history` | `0` | 0 hallazgos en archivos candidatos del árbol de trabajo. |
| **Escáner de publicación (historia)** | `PYTHONPATH=src python3 -m seminario_lab.publication` | `0` | 0 hallazgos en objetos e historia de commits de Git. |
| **Gitleaks en historia de Git** | `.local/tools/gitleaks git --redact --no-banner --log-opts=--all .` | `0` | 17 commits analizados; 0 secretos detectados en el historial. |
| **Gitleaks en directorio de trabajo** | `.local/tools/gitleaks dir --redact --no-banner .` | `1` | 24 coincidencias analizadas: todas confinadas a archivos ignorados (`.local/`, `.env.local`, `dist/`). |
| **Inspección de `preview.html`** | Inspección estructural de paquete autónomo | `0` | 2.901.996 bytes, autónomo, contiene 48 operaciones analizables y 40 sesiones. |

---

## 3. Estado de seguridad y archivos sensibles

1. **Historial de Git limpio:** El escaneo con Gitleaks y con `publication.py` sobre todos los commits históricos arrojó **0 fugas de secretos**.
2. **Archivos de trabajo:** Los archivos candidatos para entrega (tracked y untracked no ignorados) no contienen claves privadas, tokens ni rutas personales.
3. **Aislamiento de archivos locales:** Las 24 advertencias detectadas por Gitleaks en el análisis exhaustivo del directorio corresponden exclusivamente a:
   * Tokens y credenciales de prueba en `.local/` (directorio ignorado por `.gitignore`).
   * `.env.local` de la aplicación web (ignorado por `.gitignore`).
   * `dist/config.json` generado en build local (ignorado por `.gitignore`).
4. **Regla de oro de distribución:** Se debe recordar al propietario no empaquetar el directorio raíz completo a ciegas mediante un archivo ZIP para evitar la inclusión inadvertida de archivos ignorados locales.

---

## 4. Temas pendientes para decisión del propietario

1. **Configuración del remoto Git:** El remoto `origin` actual sigue apuntando al repositorio del Seminario 2. El propietario debe crear el nuevo repositorio en GitHub (o configurar su destino) y realizar el `git push` definitivo.
2. **Decisión de derechos de autor:** Se identifican 50 transcripciones de libros en `base_de_conocimientos/` y manuales en `MT5/knowledge/`. Se recomienda evaluar si publicar una versión inicial sin este corpus (mediante una rama limpia o desindexación deliberada), recordando que `.gitignore` no afecta a archivos ya rastreados en Git.
3. **Segunda etapa de integración:** La incorporación de BREAKOUT3 en el catálogo de estrategias y su cobertura en el pipeline de CI se documenta para una fase técnica posterior.

---

[Volver a ENTREGA.md](../ENTREGA.md) · [Volver al índice](../README.md).
