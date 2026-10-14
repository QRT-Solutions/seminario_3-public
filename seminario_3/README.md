# Seminario 3 — Bitácora MT5 conectada a la nube

Autoría: QRT Solutions. Edición documental: 8 de octubre de 2026.

Este módulo reúne el trabajo completo de integración: telemetría de MT5 a Supabase,
dashboard en Vercel, bot de Telegram para motivos de apertura/cierre y edición
restringida desde la web. El alumno reproduce el recorrido con su propio entorno.

**Empieza por [Empieza aquí (Primer ejercicio sin credenciales)](guias/EMPIEZA_AQUI.md)** o continúa directo con la **[guía completa del alumno](guias/README.md)**. Si vas a trabajar
con Codex, Claude Code o Antigravity, copia el [mensaje para tu agente](guias/PROMPT_AGENTE.md).

## Mapa de instrucciones

| Necesitas | Documento |
|---|---|
| Primer ejercicio sin claves ni MT5 | [Empieza aquí](guias/EMPIEZA_AQUI.md) |
| Instalar de principio a fin | [Guía completa](guias/README.md) |
| Seguir un paso a paso abreviado | [Resumen de configuración](guias/RESUMEN_CONFIGURACION.md) |
| Presentar el recorrido hoy | [Ayuda memoria docente](material/AYUDA_MEMORIA.md) |
| Saber qué está probado y qué falta | [Estado, versiones y evidencias](ESTADO.md) |
| Conectar y compilar con MT5 | [MCP nativos y exportador](integraciones/metatrader/README.md) |
| Crear Supabase | [Configuración](supabase/CONFIGURACION.md) |
| Aplicar SQL sin saltar dependencias | [Orden del esquema y verificaciones](supabase/sql/README.md) |
| Configurar credencial, EA y WebRequest | [Receptor de telemetría](supabase/RECEPTOR.md) |
| Entender campos y límites | [Contrato de datos](supabase/CONTRATO_DATOS.md) |
| Publicar la demo | [Dashboard en Vercel](aplicaciones/web/README.md) |
| Presentar diez KPI antes de integrarlos | [Laboratorio estadístico local](aplicaciones/kpi-laboratorio/README.md) |
| Crear el bot y recibir avisos | [Telegram desde BotFather](integraciones/telegram/README.md) |
| Editar motivos en el dashboard | [Acceso, edición e historial](aplicaciones/web/EDICION.md) |
| Comprobar la instalación | [Plan de pruebas](pruebas/README.md) |
| Practicar y enseñar | [Ejercicios](ejemplos/README.md) y [guion docente](material/README.md) |
| Registrar tu instalación | [Plantilla privada](guias/REGISTRO_INSTALACION.md) |
| Preparar la distribución | [Entrega al alumno](ENTREGA.md) |
| Consultar decisiones y pruebas históricas | [Bitácora](supabase/BITACORA.md) |

## Estado resumido

El receptor, el dashboard, el bot vinculado y los avisos se probaron en la demo
del docente. La edición web está implementada y desplegada, con pruebas locales
y SQL; la primera sesión real del propietario no se ha confirmado en el registro.
La fuente del EA en el clon es v3.40; se verificaron su compilación sin errores ni
advertencias, activación y recepción de datos. Consulta [ESTADO.md](ESTADO.md) para evitar confundir código incluido con
validación de cada instalación.

El dashboard tiene lectura pública **optativa** y edición restringida. Solo se
modifican los motivos humanos; los comentarios originales de MT5 y los datos
financieros se conservan. El cierre remoto permanece desactivado.

## Base heredada y migración selectiva

Se mantienen el [catálogo de estrategias](../docs/strategies.md),
[contratos](../quant_agentic_swarm/docs/ARCHITECTURE.md),
[herramientas de datos MT5](../MT5/DATA_INJECTION_GUIDE.md) y la formación cuantitativa
existentes. La skill local completa y [cuatro manuales seleccionados](../MT5/knowledge/INDEX.md)
permiten trabajar sin el repositorio privado anterior. No se duplican los bridges
antiguos, servidores stdio ni los 21 manuales de origen.

La presentación del seminario 2 continúa en `masterclass/`. El seminario 3 incluye
un guion y ejercicios propios; todavía no tiene una presentación de diapositivas
independiente. Los históricos y notebooks privados no se distribuyen.

[README principal](../README.md) · [Arquitectura](../docs/architecture.md).
