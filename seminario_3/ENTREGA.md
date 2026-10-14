# Entrega del repositorio a los alumnos

> **Autoría institucional:** QRT Solutions  
> **Ámbito:** Guía y protocolo de preparación para la entrega pública del Seminario 3 por el propietario.  
> **Corte documental:** 13 de octubre de 2026.

> [!IMPORTANT]
> **Aviso de Alcance Prioritario (Preparación Pública):**  
> Por directiva del propietario, **Seminario 2 se conserva como la BASE integral de este repositorio** (presentación masterclass, catálogo de 17 estrategias y bibliografía se conservan, sujetos a saneamiento futuro de narrativas y revisión independiente de derechos). La entrega pública final mantiene la prohibición estricta de incluir **datos de transacciones** (reales, sintéticas o simuladas) y resultados de cuentas, quedando los fixtures transaccionales del laboratorio KPI (`fixture.json` y el bundle de datos de `preview.html`) fuera de la entrega distribuible. Consulta la matriz de saneamiento y el alcance en [ALCANCE_SIN_DATOS.md](ALCANCE_SIN_DATOS.md). Los textos y guías previas se preservan en este espacio como referencia histórica y técnica en desarrollo, quedando el árbol actual con muestras pendiente de saneamiento.

La entrada de aprendizaje para el alumno es la [Guía completa del alumno](guias/README.md) (Ruta Técnica) o [Empieza aquí](guias/EMPIEZA_AQUI.md) (Ruta Introductoria sin credenciales). Los archivos de implementación y docencia residen en el mismo árbol del repositorio: no es necesario reconstruir código ni instrucciones desde chats previos.

---

## 1. Checklist de contenido seleccionable para la entrega

El contenido del repositorio preparado localmente se clasifica en los siguientes componentes modulares:

| Componente | Ruta en el repositorio | Estado y contenido seleccionable |
|---|---|---|
| **Guías pedagógicas** | `seminario_3/guias/` | `EMPIEZA_AQUI.md` (primer ejercicio visual), `README.md` (recorrido técnico), `RESUMEN_CONFIGURACION.md` y `PROMPT_AGENTE.md`. |
| **Laboratorio 10 KPIs** | `seminario_3/aplicaciones/kpi-laboratorio/` | `preview.html` autónomo, motor estadístico `engine.mjs`, tests unitarios y fixtures simuladas (React). |
| **Aplicación web** | `seminario_3/aplicaciones/web/` | Código en Vanilla HTML/CSS/JavaScript + Chart.js, tests Node, build estático (`scripts/build.mjs`) y configuración Vercel. |
| **Esquema de datos** | `seminario_3/supabase/sql/` | 12 referencias SQL ordenadas (no un proyecto CLI versionado), verificaciones y consultas RLS. |
| **Edge Functions** | `seminario_3/supabase/functions/` | `mt5-telemetry` (receptor), `mt5-telegram` (bot) y `mt5-dashboard-editor` (sesiones web). |
| **Exportador MT5** | `MT5/MT5_Telemetry_Exporter_Universal.mq5` | Código fuente institucional v3.40 (solo lectura, sin funciones de trading ni DLL). |
| **Inyección y desbloqueo** | `MT5/scripts/` | `Script_Universal_Rates_Injector.mq5` y `Script_Unlock_Custom_Symbols_Sessions.mq5` (solución error 10018). |
| **Formación cuantitativa** | `MT5/GUIA_100_PREGUNTAS_TRADING_CUANTITATIVO.md` | Guía canónica de 100 preguntas en 4 pilares y manual de auditoría de backtesting en 3 módulos. |
| **Catálogo de estrategias** | `quant_agentic_swarm/strategies/` | 17 estrategias cuantitativas institucionales (fuentes Pine Script v6 y MQL5 POO con contratos JSON). |
| **Masterclass base** | `masterclass/` | Presentación interactiva y guion docente del Seminario 2. |
| **Documentación estática** | `docs/` | Arquitectura, inicio rápido, metodología, validación y glosario para MkDocs. |
| **Herramientas de verificación** | `tools/` | Verificador de enlaces internos (`check_links.py`), hooks de MkDocs y manifiestos de seguridad. |

---

## 2. Aislamiento estricto de archivos privados y excluidos

Antes de empaquetar o publicar el repositorio, se debe verificar que ningún archivo sensible o de configuración local sea incluido:

> [!CAUTION]
> **Archivos privados que NUNCA deben publicarse ni distribuirse a los alumnos:**
> 
> * **Directorio `.local/`:** Contiene historiales de prueba, credenciales temporales emitidas, diagnósticos y baselines locales.
> * **Variables de entorno con valores reales:** `.env.local`, `.env`, y cualquier archivo `.env.*` (solo se distribuyen `.env.example` y `config.example.toml` con placeholders).
> * **Archivos de credenciales privadas:** `*.private.json`, tokens generados y archivos `.set` de MetaTrader con contraseñas o tokens reales.
> * **Configuraciones de agentes y conectores locales:** `.mcp.json`, `mcp_config.json`, `.codex/`, `.claude/`, `.antigravity/`.
> * **Artefactos compilados y dependencias:** `node_modules/`, `.venv/`, `dist/`, `.vercel/`, binarios compilados `*.ex5` y accesos directos `*.lnk`.
> 
> **Advertencia sobre exportación:** Nunca comprimas ni exportes la carpeta de trabajo completa como un archivo ZIP sin excluir estos elementos ignorados.

---

## 3. Decisión crítica sobre derechos de terceros y propiedad intelectual

El repositorio incluye carpetas heredadas cuyo régimen de derechos de autor requiere una **decisión expresa del propietario** antes de cualquier distribución pública abierta:

### A. Corpus de literatura de trading (`base_de_conocimientos/`)
* **Naturaleza del contenido:** Contiene 50 documentos en Markdown que recopilan transcripciones, resúmenes extensos y digitalizaciones de libros comerciales de trading de reconocidos autores internacionales (John Murphy, Alexander Elder, Jack Schwager, Mark Minervini, Larry Connors, Edwards & Magee, Robert Fischer, John Carter, etc.).
* **Régimen de derechos:** La licencia MIT del repositorio (que cubre el código de software, contratos y material docente original de QRT Solutions) **NO APLICA** a estas obras de terceros.
* **Advertencia legal:** Antiguas notas de procedencia o citas en el repositorio **NO constituyen autorización legal de redistribución**.

### B. Manuales técnicos importados (`MT5/knowledge/`)
* **Naturaleza del contenido:** Manuales técnicos importados sobre arquitectura interna de MetaTrader 5 y guías exhaustivas de Strategy Tester.
* **Régimen de derechos:** Debe revisarse su procedencia original y términos de redistribución antes de su entrega pública.

### C. Advertencia fundamental sobre Git y `.gitignore`
* **Importante:** Añadir una carpeta a `.gitignore` **NO ELIMINA** archivos que ya estén rastreados (*tracked*) en el árbol de trabajo o que formen parte de commits previos en el historial de Git.
* Si un archivo ya fue añadido a Git, continuará existiendo en el repositorio y en cualquier clon a menos que se elimine expresamente del índice o se prepare una rama de publicación limpia.

### D. Revisión independiente de derechos (sin exclusión automática)
* **Criterio institucional:** `base_de_conocimientos/` y `MT5/knowledge/` no se excluyen automáticamente por pertenecer a Seminario 2. Su distribución o separación se resolverá mediante una **decisión independiente sobre derechos de autor y licencias de terceros**. No se asumen autorizaciones legales definitivas y el corpus no se borra.
* **Acción en este encargo:** El agente **NO borra ningún corpus, NO altera el archivo `LICENSE` y NO reescribe el historial de Git**. Todo el material se preserva intacto en el árbol actual a la espera de la resolución específica de licencias por el propietario.

---

## 4. Revisión técnica antes de compartir

Sigue esta secuencia de control en tu entorno local:

1. **Pruebas de suites Node.js:**
   ```bash
   npm test --prefix seminario_3/aplicaciones/web
   node --test seminario_3/supabase/functions/mt5-telemetry/*.test.mjs
   node --test seminario_3/supabase/functions/mt5-telegram/*.test.mjs
   node --test seminario_3/supabase/functions/mt5-dashboard-editor/*.test.mjs
   node --test seminario_3/aplicaciones/kpi-laboratorio/tests/*.test.mjs
   ```
2. **Comprobación de enlaces internos:**
   ```bash
   python3 tools/check_links.py
   ```
   Debe arrojar `0 failures`.
3. **Escaneo de secretos con Gitleaks:**
   ```bash
   .local/tools/gitleaks dir --redact --no-banner .
   .local/tools/gitleaks git --redact --no-banner --log-opts=--all .
   ```
   *Nota:* Si el escáner reporta alguna coincidencia, revisa su ubicación y tipo sin divulgar valores en chats públicos.
4. **Verificación de exclusión de archivos privados:**
   Revisa `git status --short` para asegurar que ningún archivo bajo `.local/` o `.env.local` aparezca marcado para inclusión.

---

## 5. Publicación Git pendiente

En esta copia local de trabajo, el remoto Git configurado (`origin`) continúa apuntando al repositorio del Seminario 2:

> [!WARNING]
> **No ejecutar `git push` al remoto heredado.**  
> La publicación del Seminario 3 requiere que el propietario configure el repositorio remoto de destino definitivo en GitHub, prepare el commit inicial de entrega y realice el push correspondiente de forma manual. No se han creado remotos ficticios ni alterado ramas remotas.

Cuando el propietario autorice y cree el nuevo repositorio remoto:
1. Revisar el diff y los archivos seleccionados para la entrega.
2. Confirmar la decisión sobre `base_de_conocimientos/` y `MT5/knowledge/`.
3. Configurar el nuevo remoto: `git remote set-url origin <URL_DEL_NUEVO_REPOSITORIO>`.
4. Efectuar el commit y push de publicación.
5. Realizar una prueba de clon limpio desde una carpeta independiente para certificar la experiencia de un alumno nuevo.

---

[Volver al índice del seminario](README.md) · [Estado de evidencias](ESTADO.md).
