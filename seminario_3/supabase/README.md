# Supabase

Autoría: QRT Solutions.

Esta guía permite a cada alumno preparar **su propio proyecto de desarrollo** con
Codex, Claude Code o Antigravity. El agente descubre las herramientas disponibles
en cada equipo; no necesita credenciales ni acceso al proyecto del docente.

## Estado del recorrido

| Parte | Estado |
|---|---|
| Proyecto y conexión del agente | Procedimiento documentado y verificado en el entorno docente |
| Tablas con acceso restringido | Tres iniciales y 17 en el recorrido completo; orden SQL y consultas de comprobación disponibles |
| EA de telemetría | v3.40 compilada sin errores/advertencias, activa y con recepción real verificada en el entorno docente; verificar cada instalación |
| Receptor con credencial por cuenta | Implementado; credenciales restringidas y revocables, registro de hashes protegido |
| Envío MT5 → Supabase | Verificado desde el EA en el entorno docente; repetir comprobación en cada equipo |
| Dashboard público de una demo | Consulta limitada y aplicación Vercel implementadas; publicación optativa |
| Bot de bitácora en Telegram | Chat vinculado; aviso de apertura y motivo por respuesta directa verificados en la demo docente |

Para una instalación completa, comienza por la [guía del alumno](../guias/README.md)
y aplica el [orden de SQL](sql/README.md). Consulta el [estado preciso](../ESTADO.md)
antes de interpretar los registros históricos.

## Recorrido

1. Sigue la [configuración paso a paso](CONFIGURACION.md).
2. Consulta el [contrato de datos y parámetros del EA](CONTRATO_DATOS.md).
3. Instala el [receptor y configura el EA](RECEPTOR.md) con tu propia credencial.
4. Revisa la [bitácora y punto de continuación](BITACORA.md) antes de retomar.
5. Continúa con el [dashboard en Vercel](../aplicaciones/web/README.md), si quieres publicar una demo.
6. Si eres un agente, aplica el [protocolo de documentación](AGENTS.md).
7. Configura tu [bot de Telegram](../integraciones/telegram/README.md) para documentar motivos.

## Mensaje inicial para tu agente

Copia este mensaje en el agente que tenga abierto tu clon:

```text
Ayúdame a configurar Supabase para la telemetría de MT5 de este seminario.
Lee AGENTS.md y los archivos README.md, CONFIGURACION.md, CONTRATO_DATOS.md, RECEPTOR.md,
BITACORA.md y AGENTS.md dentro de seminario_3/supabase/.
Comprueba primero qué existe en mi clon y qué conectores tienes disponibles.
Usa mi propio proyecto de desarrollo y mis credenciales, no las del docente.
Si falta un dato necesario, pregúntamelo de uno en uno y explica para qué sirve.
Adapta la conexión MCP al cliente y sistema operativo que estoy usando.
Descubre las herramientas y verifica el destino antes de modificarlo.
Conserva tablas, configuraciones y migraciones existentes. No borres ni recrees
recursos para resolver diferencias sin revisar su impacto conmigo.
Ejecuta lo autorizado, verifica cada resultado y actualiza la documentación
conforme avancemos. Guarda detalles privados en .local/supabase-setup/,
excluido de Git; publica solo instrucciones y evidencia sanitizada.
No confundas una tabla creada con una conexión MT5 funcionando. Si falta el EA
o el receptor, informa de ese límite y prepara el siguiente paso concreto.
Esta tarea no autoriza trading, cierres remotos ni cambios de cuenta.
```

El conector MCP permite al **agente administrar el proyecto**. El EA utiliza HTTP
para **enviar telemetría**. Iniciar sesión en el conector no configura el EA.
Esta carpeta contiene referencias SQL; no es un proyecto Supabase CLI inicializado.

[Volver al seminario 3](../README.md).

La [edición de motivos en el dashboard](../aplicaciones/web/EDICION.md) reutiliza el
chat privado autorizado en Telegram, con códigos temporales, sesiones restringidas
y auditoría de cambios. La lectura pública no habilita escrituras anónimas.
