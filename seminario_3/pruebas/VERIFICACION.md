# Verificación de la consolidación documental

Autoría: QRT Solutions. Fecha: 8 de octubre de 2026.

Alcance: árbol local de trabajo, incorporando los archivos nuevos todavía sin
commit. No certifica una revisión remota ni una instalación independiente de alumno.
No se modificaron datos ni servicios de Supabase, Telegram, Vercel o MT5 en esta tarea.

| Control | Resultado |
|---|---|
| Catálogo heredado | 17 estrategias, cero errores de verificación |
| Contratos y esquemas de skill MT5 | 63 aprobados, cero fallos; sin llamadas nativas |
| Generación local de credenciales | 3 pruebas aprobadas |
| Funciones de telemetría, avisos, bot y editor | 30 pruebas Node aprobadas |
| Dashboard | 7 pruebas Node aprobadas |
| Build web desde copia de archivos públicos | `npm ci` y build aprobados sin `.env.local`, usando valores de ejemplo; no acredita conectividad |
| Enlaces de documentación | Cero fallos; se mantienen 3.355 referencias históricas no disponibles del corpus importado, con hashes de origen sin cambios |
| MkDocs | Construcción con `--strict` aprobada |
| Hook de documentación | Ruff aprobado |
| Escáner de publicación propio | Sin hallazgos en archivos candidatos e historia local |
| Gitleaks 8.30.1, árbol distribuible | 335 archivos candidatos sin hallazgos, incluidos archivos nuevos, excluyendo configuración privada |
| Gitleaks 8.30.1, historia Git | 16 commits revisados, sin hallazgos |
| Archivos privados en sitio generado | No se encontraron configuraciones/JSON privados, logs, binarios EA ni accesos directos |
| Documentación principal y seminario 3 | Sin rutas personales ni identificadores de conexión del docente en la revisión específica |

Los escáneres son heurísticos. La revisión privada usa un árbol con los archivos
que Git considera candidatos; no incluye `.local/`, archivos de entorno reales,
conexiones MCP o accesos directos locales. Los resultados completos se mantienen
fuera de Git; este documento solo publica su resumen.

## Correcciones realizadas al consolidar

- Sustitución de índices desactualizados que marcaban Telegram como pendiente.
- Separación de fuente EA v3.30 y evidencia histórica de compilación v3.20.
- Orden SQL explícito antes de enviar los campos de comentarios desde el EA.
- Inclusión de `editor.mjs` en la lista documental de despliegue web.
- Recorrido completo, prompt para agentes, ejercicios, guion y registro privado.
- Navegación MkDocs y exclusiones para preparar una entrega sin archivos del equipo.

## Pendientes que no se certifican

Compilación y recepción nativas de v3.30, primera sesión real del propietario en
el editor, recorrido completo de un alumno desde un clon limpio y portabilidad
completa entre clientes/sistemas. La publicación Git del seminario 3 también está
pendiente: no se hizo commit/push y el remoto heredado sigue apuntando al seminario 2.

[Comandos reproducibles](README.md) · [Entrega](../ENTREGA.md) · [Estado](../ESTADO.md).

## Ampliación: ajustes simples (8 de octubre de 2026)

Autoría: QRT Solutions.

- 37 pruebas de funciones y 7 del dashboard: aprobadas.
- SQL local y remoto con ROLLBACK: captura, agrupación, reenvíos, propiedad,
  revisiones, conflictos y páginas de 30 deals sintéticos: aprobado.
- Navegador 390/1440 px: sin errores ni desbordamiento; guardado SL/TP simulado
  y paginación en servidor aprobados. No se escribieron razones ficticias en nube.
- Vercel producción: READY, lectura móvil real HTTP 200 y hashes de assets iguales
  al build local. API de edición sin sesión 401, origen ajeno 403, tabla privada 401.
- Documentación y enlaces comprobados; escáner de publicación sin hallazgos.
- Fuente v3.40 enviada a Experts con contrato/hash. Compilación e instalación
  pendientes de disponibilidad del MCP de MetaEditor; el EA activo se conservó.

Estas verificaciones no sustituyen una prueba voluntaria del propietario con un
cambio de protección real después de instalar el binario nuevo.


## 8 de octubre de 2026 — compilación nativa v3.40 completada

Autoría: QRT Solutions.

Tras habilitar MetaEditor, se redescubrió su compilador nativo y se comprobó
que la fuente en Experts coincide por SHA-256 con la del repositorio.
Compilación x64 con MetaEditor build 6230: **0 errores y 0 advertencias**.
Lectura posterior del binario por MCP: firma EX5 y 40 542 bytes. La evidencia
completa, el contrato y los hashes permanecen en el registro local excluido de Git.

El binario nuevo está disponible en `MQL5/Experts`. Para verlo sin reiniciar:
Navegador → Asesores Expertos → clic derecho → Actualizar. Compilar no sustituye
el EA del gráfico: su activación y la recepción de cambios SL/TP de v3.40 siguen
pendientes. El cierre remoto permanece desactivado.


## 8 de octubre de 2026 — textos de configuración y autoría

Autoría: QRT Solutions.

Se retiraron los ejemplos del rótulo «Nombre del Proyecto» del exportador.
Los metadatos muestran `QRT Solutions` y enlazan a `https://www.qrtsolutions.com`.
El valor predeterminado del proyecto y la lógica de telemetría se conservan.
La revisión v3.40 con fuente SHA-256 `2ad776d3c18b093e8e06ab7890c67d61368677360393787d0ce7774716d2de57`
se compiló mediante MCP nativo: 0 errores y 0 advertencias; binario de 40 866
bytes verificado por lectura posterior. Se generó en un archivo nuevo de Experts;
la activación en el gráfico sigue pendiente.


## 8 de octubre de 2026 — recepción de v3.40 confirmada

Autoría: QRT Solutions.

Se comprobó mediante MCP que la revisión v3.40 de autoría actualizada está activa
en el gráfico, con latido de 30 segundos y cierre remoto desactivado. El nombre
de proyecto inicialmente no coincidía con el autorizado y causaba HTTP 403 en
snapshots e historial. Tras corregirlo el propietario, ambos envíos devolvieron
HTTP 200. La consulta directa a Supabase confirmó un snapshot recibido 29 segundos
antes de la verificación (13:57 UTC). No se generaron operaciones de prueba.

Para los alumnos: copiar exactamente `InpProjectName` de la configuración
emitida, incluidos guiones y mayúsculas. Una credencial válida no autoriza otro
nombre de proyecto. La recepción de snapshots e historial no certifica todavía
el recorrido de un cambio real SL/TP → aviso Telegram → motivo registrado.


## 8 de octubre de 2026 — motivos de ejemplo solicitados por el propietario

Autoría: QRT Solutions.

Carga expresamente autorizada para la demo pública: 99 motivos de apertura y
100 de cierre, agrupados en 20 grupos de apertura y 14 de cierre. Cada texto lleva
«Ejemplo didáctico»; los motivos de intención se señalan como ficticios. Los dos
cierres simultáneos por TP comparten una descripción basada en su ejecución.

Se conservaron los cinco motivos previos y los datos nativos de MT5. La escritura
transaccional verificó cuenta DEMO publicada, fases existentes, campos vacíos y
versiones sin cambios concurrentes; ensayo con ROLLBACK antes del COMMIT.
Se guardaron respaldo y plan privados, y 199 entradas de auditoría con actor
administrativo 0 en `mt5_web_reason_audit`. El historial web muestra origen `web`
por la tabla reutilizada; estas entradas proceden de SQL administrativo autorizado,
no de Telegram ni de una sesión del propietario suplantada.

Consulta posterior: 102 operaciones, cero motivos de apertura/cierre pendientes,
34 grupos con textos idénticos por grupo y cinco motivos originales intactos.
La consulta HTTP pública usada por el dashboard verificó las 11 páginas y los
199 ejemplos. No se alteraron comentarios del broker, precios, resultados ni
operaciones de MT5. Véase [uso de muestras](../aplicaciones/web/EDICION.md).


## 8 de octubre de 2026 — motivos breves por solicitud del propietario

Autoría: QRT Solutions.

Se abreviaron los 199 motivos de la muestra, retirando el prefijo visible y las
explicaciones largas. Las frases indican el efecto buscado, como «Capturar
continuación tras ruptura alcista», «Reducir exposición» o «Salida por take profit».
Se mantuvieron los grupos y los cinco motivos previos del propietario. La fuente
de los 199 textos sigue siendo una muestra sintética, no intención real acreditada.

Carga transaccional con comparación del texto y versión anteriores, restringida
a la demo publicada. Se guardaron 199 revisiones nuevas con actor administrativo
0 y `previous_reason` conservando el texto didáctico original. Verificación HTTP
pública de las 11 páginas: 199 cambios correctos, cinco textos conservados, cero
motivos pendientes en las 102 operaciones revisadas. No se alteró MT5.


## Resumen de configuración y ayuda memoria (8 de octubre de 2026)

Autoría: QRT Solutions.

Resumen y guion docente incorporados a índices y MkDocs. Build estricto aprobado,
enlaces internos con cero fallos y escáner de publicación sin hallazgos. Se
comprobaron las tablas HTML generadas de ambos documentos y los diez pasos SQL
en una sola tabla. Las 3355 referencias históricas no disponibles del corpus
importado siguen registradas como baseline; sus hashes no cambiaron. No se
reconfiguraron servicios ni se publicaron commits durante esta tarea documental.


## 8 de octubre de 2026 — dos guías HTML portables

Autoría: QRT Solutions.

Se generaron [Configuración](../material/html/configuracion.html) y
[Ayuda memoria](../material/html/ayuda-memoria.html) desde las fuentes Markdown.
Incluyen navegación, referencias directas desplegables, copia de comandos, modo
presentación, tablas móviles e impresión del contenido principal. Los dos
archivos se comparten juntos; su lectura no hace peticiones de red. Se incluyó
el generador reproducible `tools/build_seminario3_handouts.py`.

Verificados en navegador a 390 y 1440 px: sin desbordamientos, enlaces internos
rotos, IDs duplicados ni errores JavaScript. Comprobados copia de comandos,
referencias desplegables, modo presentación e impresión; revisión visual de
escritorio y celular. MkDocs estricto y enlaces internos aprobados. No se
desplegaron sitios ni se cambiaron servicios.


## 8 de octubre de 2026 — adaptación visual al dashboard Dual

Autoría: QRT Solutions.

Se adoptó el estilo de `dashboard_traders_dual.html`: logo original, cabecera y
metadatos compactos, seis tarjetas del snapshot, cuatro resúmenes coloreados,
gráficos antes de las bitácoras, accesos por sección y distintivos BUY/SELL.
La cifra añadida, margen utilizado, procede directamente del snapshot existente.
No se importaron los registros de la referencia ni sus métricas porcentuales.
Comentarios de apertura, cierre y cambios SL/TP mantienen la edición autorizada.

Verificaciones locales: siete pruebas unitarias aprobadas; compilación y sintaxis
correctas; HTML sin IDs duplicados ni errores de anidación. Lectura pública real
con 25 ejecuciones y 10 operaciones por página. Revisión visual y sin desbordes
ni errores JavaScript a 320, 390, 768 y 1440 px. Se comprobaron filtro de símbolo,
restablecer, rango vacío, paginación independiente, exportación y correspondencia
de puntos del gráfico con la página. Sesión y guardado de un motivo SL/TP probados
a 390/1440 px con respuestas interceptadas, sin escrituras remotas.

Publicado en el proyecto Vercel existente mediante CLI autenticada, tras rechazo
de alcance del conector MCP. Estado READY; el dominio público sirve los mismos
bytes HTML, CSS, JavaScript y logo del build validado. Revisión de producción a
390/1440 px con datos reales, gráficos y configuración del editor sin errores.
No se modificaron tablas, funciones, motivos ni la instalación de MT5.

## 8 de octubre de 2026 — logo Pepperstone

Autoría: QRT Solutions.

Se trasladó el PNG proporcionado por el propietario a
`seminario_3/aplicaciones/web/src/pepperstone.png` y se sustituyó el logo de la
cabecera, con texto alternativo Pepperstone. Build y servidor local incluyen el
recurso PNG. Compilación aprobada; imagen de 512 × 512 cargada en escritorio
(1440 px) y celular (390 px), sin desbordes ni errores JavaScript. Despliegue
Vercel READY y logo verificado en el dominio público a ambos tamaños.
Documentación y copias HTML actualizadas; enlaces internos sin fallos.
