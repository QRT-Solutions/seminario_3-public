# Ajustes simples del flujo

Autoría: QRT Solutions. Diseño aprobado: 8 de octubre de 2026.

Se conserva la arquitectura MT5 → Supabase → Telegram y dashboard en Vercel.
Telegram registra razones; no modifica posiciones. El cierre remoto permanece
desactivado. No se incorporan IA, proveedores de noticias ni captura de ticks.

## Alcance y decisiones

1. Comparar SL/TP de posiciones con identificador estable entre estados recibidos.
   La primera observación es una referencia inicial, no un cambio. Guardar cada
   diferencia observada y agrupar las preguntas por posición y minuto UTC.
2. Conservar comentarios nativos y explicaciones humanas por separado. Permitir
   registrar y corregir motivos de cambios, con auditoría, desde Telegram y web.
3. Mostrar tarjetas en móvil y tablas en escritorio, con lectura demo pública
   y edición limitada al propietario ya vinculado.
4. Paginar historial y bitácora en el servidor. Mostrar por separado totales de
   todo el filtro y gráficos/exportación de la página descargada.

## Límites deliberados

Un snapshot permite identificar cambios observados, no reconstruir modificaciones
intermedias durante desconexiones. Un minuto de agrupación reduce avisos de
trailing; la entrega posterior depende de los latidos del exportador. La hora
de observación procede del snapshot UTC; no representa una ejecución del broker.
Las preguntas de apertura/cierre existentes siguen siendo por posición y fase.

## Secuencia de trabajo y aceptación

- Preparar SQL incremental, validar autenticación y pruebas con rollback.
- Extender receptor y bot sin romper payloads antiguos.
- Actualizar y compilar exportador mediante MCP nativo, sin abrir operaciones.
- Adaptar dashboard, probar móvil/escritorio y paginación.
- Desplegar componentes compatibles y verificar lecturas y permisos.
- Actualizar guías y evidencia, distinguiendo pruebas sintéticas de eventos reales.

Se comprueban duplicados, primer estado, cambios sin variación, SL retirado,
agrupación, cuenta ajena, sesión vencida, revisión concurrente y paginación.

## Evidencia de esta ejecución

Supabase, Telegram y Vercel están actualizados; permisos, paginación y edición se
verificaron con pruebas controladas. Ver [registro de pruebas](../pruebas/VERIFICACION.md).
La fuente v3.40 se compiló mediante MCP nativo de MetaEditor: 0 errores y
0 advertencias; binario EX5 verificado. La versión v3.40 está activa en el
gráfico: snapshot reciente confirmado en Supabase e historial con HTTP 200.
Sigue pendiente comprobar un cambio real de SL/TP y su motivo por Telegram.
