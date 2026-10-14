# Estado, versiones y evidencia

Autoría: QRT Solutions. Corte documental: 8 de octubre de 2026.

Esta tabla describe el trabajo registrado en el entorno docente. No certifica
que un clon nuevo ya esté conectado ni que se hayan probado todos los clientes.
La [bitácora histórica](supabase/BITACORA.md) conserva los detalles cronológicos.

| Componente | Disponible en el repositorio | Evidencia y límite |
|---|---|---|
| Base heredada | Catálogo, contratos, scripts, metodología y presentación anterior | Sus pruebas son independientes de la integración nube |
| Operación MT5 | Skill local, esquemas, pruebas y cuatro manuales | Pruebas offline; servicios MCP se descubren en cada equipo |
| Exportador EA | Fuente v3.40, sin credenciales ni funciones de trading | v3.40 compilada por MCP nativo: 0 errores, 0 advertencias; activa en gráfico, snapshot recibido e historial HTTP 200 verificados |
| Supabase | Doce referencias SQL principales, tres funciones Edge y consultas | Instalación y recepción reales verificadas en el proyecto docente |
| Credencial MT5 | Generador local con hash, alcance y revocación | Identidad y acceso restringido comprobados; secreto no distribuido |
| Dashboard | Código, lockfile, build, pruebas y configuración Vercel | Producción READY y lectura pública real verificadas |
| Comentarios | Apertura/cierre, metadatos y motivos humanos separados | Motivos visibles; comentarios nativos requieren recepción desde fuente compatible |
| Telegram | Creación, secreto, instalador temporal, webhook y vinculación | Bot definitivo y chat vinculado verificados; usuario confirmó `/pendientes` |
| Avisos de apertura/cierre | Cola, reintentos y respuesta ligada al mensaje | Apertura y respuesta verificadas; recibo de envío de cierre documentado |
| Edición web | Código de un uso, sesión, editor e historial | Pruebas de HTTP, SQL con ROLLBACK e interfaz local aprobadas; primer acceso real del propietario pendiente de confirmación |
| Protección SL/TP | Comparación de snapshots, eventos, grupos y auditoría | SQL aplicado y EA v3.40 activo; permisos y revisiones probados con rollback; pendiente comprobar un cambio real y su motivo por Telegram |
| Dashboard móvil y páginas | Diseño inspirado en Trackrecord Dual, tarjetas, páginas en servidor y totales del filtro | Pruebas locales 320/390/768/1440 px; producción verificada a 390/1440 px, edición probada con respuestas simuladas |
| Diez KPI del dashboard | Tarjetas y RPC agregada sobre operaciones completas | SQL local y diez pruebas Node aprobadas; producción READY verificada a 320/390/768/1440 px con 108 operaciones; drawdown y riesgo con posiciones requieren telemetría adicional |
| Distribuciones y curvas | Histogramas porcentual/monetario y acumulados del filtro completo | SQL y 13 pruebas Node aprobados; producción READY verificada a 1440/390/320 px; hasta 400 puntos con agrupación explícita, sin equity histórica |
| Documentación docente | Recorrido, resumen de configuración, ayuda memoria, prompt, mapa SQL, ejercicios y registro | Enlaces y construcción estática se verifican al preparar la entrega |
| Motivos de muestra | Procedimiento y procedencia documentados; datos solo en la demo | 199 motivos breves de muestra, cinco originales conservados, 102 operaciones verificadas; no certifican intención real |

## Qué significa «probado»

- **Offline:** ejecuta código con casos controlados; no contacta servicios.
- **Compilado:** el compilador produjo un binario de esa fuente específica.
- **Desplegado:** el proveedor aceptó y publicó los archivos; falta comprobar el uso.
- **Recepción real:** registros leídos en Supabase y contrastados con el origen.
- **Validado por el propietario:** la persona usó su bot o dashboard y confirmó el resultado.

No sustituir una evidencia por otra. No se ha ejecutado el recorrido completo desde
un clon limpio por un alumno independiente en Windows, Codex, Claude Code y
Antigravity. Los agentes deben adaptar la instalación, no declarar portabilidad probada.

## Límites funcionales actuales

| Límite | Implicación |
|---|---|
| Una cuenta por proyecto y un bot por proyecto | Revisar claves y alcance antes de un servicio multiusuario |
| Snapshot sobrescrito | No existe serie histórica de equity |
| Hora del broker etiquetada por el EA sin normalizar | No usarla como UTC para análisis intradiario |
| Precios y volumen con ocho decimales en v3.40 | Datos previos no recuperan precisión descartada |
| Sin MAE/MFE ni riesgo inicial | Esas métricas aparecen no disponibles |
| Un motivo por posición y fase | Cierres parciales comparten motivo; no se solicitan de nuevo por cada parcial |
| Eventos de MT5 sin cola durable completa | Una desconexión puede omitir un aviso; histórico y avisos son mecanismos distintos |
| Reintentos Telegram ligados a recepciones de telemetría | Sin nuevas recepciones no hay entrega de reintentos independiente |
| Red y colas | No se garantiza latencia instantánea ni entrega exactamente una vez |
| Estado cada 30 s; historial cada 2 min | Actualizar fuerza consulta; un motivo puede tardar en aparecer a otro visitante |
| Sesión web en memoria, una hora | Recargar exige otro código; origen Preview/local no autorizado por defecto |
| Datos de prueba del docente | No vienen en el clon ni deben copiarse al proyecto de un alumno |

## Estado de distribución

El trabajo está preparado en el árbol local del repositorio. El remoto configurado
sigue siendo el de `seminario_2-public`; no se ha creado un remoto nuevo ni hecho
commit/push del seminario 3 durante esta consolidación. No afirmar que el código
nuevo ya está disponible para clonar en una URL remota hasta publicarlo.
Sigue [ENTREGA.md](ENTREGA.md) para ese último paso.
