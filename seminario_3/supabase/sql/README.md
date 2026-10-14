# Orden del SQL — instalación completa y comprobaciones

Autoría: QRT Solutions.

Estos archivos son **referencias SQL**, no un proyecto Supabase CLI inicializado.
Se aplican como migraciones administrativas después de inspeccionar el destino.
No son idempotentes: no los ejecutes dos veces ni uses un reset para ignorar diferencias.
El agente debe conciliar el historial del proyecto con lo que ya existe.

## Instalación en un proyecto nuevo

| Orden | Archivo | Qué prepara |
|---|---|---|
| 1 | [esquema_telemetria.sql](esquema_telemetria.sql) | Tres tablas de datos y RLS |
| 2 | [receptor_telemetria.sql](receptor_telemetria.sql) | Credenciales restringidas, recepción UTC y permisos del servidor |
| 3 | [dashboard_publico.sql](dashboard_publico.sql) | Publicación optativa inicialmente vacía y RPC de lectura |
| 4 | [bitacora_trades.sql](bitacora_trades.sql) | Comentarios de MT5, motivos, editores, auditoría y RPC pública ampliada |
| 5 | [telegram_bitacora.sql](telegram_bitacora.sql) | Códigos de vinculación y consulta de motivos |
| 6 | [telegram_alertas_apertura.sql](telegram_alertas_apertura.sql) | Cola, reservas y asociación de mensajes |
| 7 | [telegram_alertas_cierre.sql](telegram_alertas_cierre.sql) | Amplía esa misma cola a cierres y reversiones |
| 8 | [dashboard_editor.sql](dashboard_editor.sql) | Códigos web, sesiones, configuración de origen y auditoría de ediciones |
| 9 | [protecciones_bitacora.sql](protecciones_bitacora.sql) | Historial de SL/TP, agrupación de avisos y edición auditada |
| 10 | [dashboard_paginado.sql](dashboard_paginado.sql) | Páginas y totales filtrados para el dashboard |
| 11 | [dashboard_kpis.sql](dashboard_kpis.sql) | Diez KPI: agregados de operaciones completas y conteos de exclusión |
| 12 | [dashboard_distribuciones.sql](dashboard_distribuciones.sql) | Histogramas y curvas sobre la misma muestra de los KPI |

Instala 1–4 antes de recibir la fuente EA v3.40: sus campos de comentarios necesitan
la cuarta extensión. El paso 3 es dependencia del paso 4 incluso si no habilitas
publicación. Crear esa estructura no selecciona ni publica una cuenta.
Para el recorrido completo conviene instalar las doce referencias antes de activar
las funciones y el EA. Deben quedar **17 tablas `mt5_`** con RLS, suponiendo que
no había otras extensiones en el proyecto.

En una instalación que ya recibe datos, la ampliación de cierre requiere que los
receptores interpreten `phase` antes de activar el paso 7. Sigue la
[guía Telegram](../../integraciones/telegram/README.md) para el orden de actualización.
No sustituir una función en producción con un paquete incompleto.

[restringir_rls_automatico.sql](restringir_rls_automatico.sql) es **condicional**:
solo aplica si existe la función administrativa concreta descrita en
[CONFIGURACION.md](../CONFIGURACION.md). No es un paso obligatorio.

## Actualizar una instalación existente

Después de revisar sus migraciones, aplicar solo 9 y 10 si faltan. Desplegar
receptor, bot y editor completos; actualizar el webhook para aceptar `message`
y `callback_query` mediante el instalador temporal y retirarlo después.
Compilar/instalar el EA v3.40 y publicar el nuevo dashboard. La API anterior sigue
existiendo para compatibilidad, pero la web nueva usa `mt5_public_dashboard_page`.
La captura requiere `position_id` en los snapshots: los clientes antiguos siguen
siendo aceptados, pero no se infiere el identificador a partir del ticket.

Para los diez KPI, aplicar el paso 11 si falta y publicar el build web actualizado.
La RPC `mt5_public_dashboard_kpis` es adicional: no sustituye la consulta paginada ni
activa publicaciones. [verificar_dashboard_kpis.sql](verificar_dashboard_kpis.sql)
usa fixtures con ROLLBACK **solo en una base local de prueba**, con el esquema de
cuenta/deals, tabla de publicación y roles `anon`/`authenticated` preparados.

Para los gráficos, aplicar el paso 12 después del 11: amplía la misma RPC con
`charts` y conserva el contrato de KPI. Ejecutar
[verificar_dashboard_distribuciones.sql](verificar_dashboard_distribuciones.sql)
solo en la base local de pruebas; utiliza fixtures con ROLLBACK, incluidos 805
cierres para verificar el límite de 400 puntos sin perder totales.

## Configuración posterior: no es esquema

Después de instalar, se registran por separado datos propios del alumno:

- Hash y alcance del token MT5: `register.sql` generado en `.local/`.
- Publicación de una sola demo: SQL de la [guía web](../../aplicaciones/web/README.md),
  únicamente si el propietario autoriza esa lectura pública.
- Hash del código `/vincular`: SQL generado por `crear_vinculo.py`.
- Origen HTTPS y bot del editor: SQL de [EDICION.md](../../aplicaciones/web/EDICION.md).

No publiques esos registros administrativos ni copies valores del docente.

## Comprobaciones

| Archivo | Alcance |
|---|---|
| [verificar_telemetria.sql](verificar_telemetria.sql) | Estructura, RLS y permisos iniciales |
| [verificar_receptor.sql](verificar_receptor.sql) | Recepción y acceso restringido del EA |
| [verificar_telegram.sql](verificar_telegram.sql) | Permisos y estado del bot sin divulgar identidad |
| [verificar_dashboard_editor.sql](verificar_dashboard_editor.sql) | Guardado, códigos, sesiones, conflictos y auditoría con `ROLLBACK` |

[verificar_protecciones.sql](verificar_protecciones.sql) añade fixtures sintéticas con `ROLLBACK` para SL/TP, revisiones, autorización y paginación. Ejecutarlo completo.

La comprobación del editor necesita un editor activo y una apertura recibida. Ejecuta
el archivo completo en una sola transacción: no ejecutes solo los fragmentos de
escritura. No deja motivos ficticios persistentes. Las consultas de conteos no
acreditan por sí solas una interacción del alumno con el bot o la web.

Si usas Supabase CLI, consulta su ayuda y genera las migraciones con
`supabase migration new`; no inventes marcas de tiempo ni ejecutes `db push` sin
reconciliar el historial remoto. Para MCP, usa la herramienta de migraciones que
ofrezca el conector. Los nombres exactos pueden variar según el cliente.

[Volver al recorrido](../../guias/README.md).
