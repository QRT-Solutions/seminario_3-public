# Protocolo de documentación de Supabase

Autoría: QRT Solutions.

Aplicar junto con el [AGENTS.md raíz](../../AGENTS.md). Cada alumno debe poder
reproducir el proceso en su proyecto con Codex, Claude Code o Antigravity.

1. Leer [README](README.md), [configuración](CONFIGURACION.md),
   [contrato](CONTRATO_DATOS.md), [receptor](RECEPTOR.md) y [bitácora](BITACORA.md)
   antes de continuar.
2. Descubrir capacidades reales del cliente, sistema operativo, destino y recursos
   existentes. Consultar documentación oficial vigente. No reutilizar IDs, rutas,
   credenciales ni permisos de la sesión del docente.
3. Respetar autorizaciones de la sesión sin volver a pedir lo ya autorizado.
   Resolver ambigüedades de destino o alcance antes de acciones dependientes.
   Esta documentación no autoriza trading ni activar un EA.
4. Con cada cambio autorizado, actualizar en la misma tarea el procedimiento,
   SQL o configuración de ejemplo, contrato afectado y bitácora. Explicar por qué
   se hace y cómo verificarlo; no limitarse a enumerar comandos.
5. Distinguir disponible en el clon, probado localmente, aplicado remotamente y
   pendiente. No afirmar portabilidad entre clientes hasta probarla.
6. Publicar solo ejemplos sin secretos ni identificadores personales. Guardar los
   detalles privados en ubicaciones locales excluidas de Git y comprobar esa
   exclusión. Nunca pedir contraseñas ni claves en el chat.
7. Revisar tablas y migraciones antes de modificar una base. Preparar diferencias
   incrementales; no borrar recursos ni ocultar incompatibilidades.
8. Verificar permisos, RLS y asesores después de DDL. Leer los datos recibidos
   antes de declarar integración completa. Registrar fallos y pendientes.
9. Comprobar enlaces y construcción de documentación tras editar estas guías.
   No realizar escrituras remotas para probar un cambio de prosa.

La obligación de documentar continúa con los próximos pasos del receptor y del EA.
