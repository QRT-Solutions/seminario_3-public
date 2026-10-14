# Arquitectura

`pyproject.toml` centraliza metadatos y dependencias. Hatchling construye el paquete;
`uv.lock` fija la resolución CPython 3.12 y `requirements.txt` exporta el núcleo
para pip. El grupo `dev` agrega tests, lint, tipos, seguridad y MkDocs.

| Componente | Responsabilidad |
|---|---|
| `src/seminario_lab/config.py` | Raíz explícita o ancestros del cwd; confinamiento de rutas |
| `validation.py` | Registro, esquema, IDs, artefactos y sincronía |
| `integrity.py` / `provenance.py` | Hashes y revisión Git identificada |
| `platforms.py` | Preparación y compilación opcionales en workspaces de pruebas |
| `publication.py` | Regresiones de secretos, rutas e historial |
| `masterclass/` | Presentación, guion y recursos locales |
| `quant_agentic_swarm/strategies/` | Fuente canónica de 17 estrategias |

No se modifica `sys.path`, no se busca configuración en carpetas del autor y no
se escribe al importar. Fuera del árbol se exige `--project`. No se cargan `.env`
ni conexiones automáticas. El núcleo no instala el stack científico de los
cuadernos retirados de esta edición.

Actualizar dependencias exige revisar, resolver, probar y exportar:

```sh
uv lock
uv export --locked --no-dev --no-emit-project --format requirements.txt --output-file requirements.txt
```

La instalación bloqueada sigue la [semántica de uv](https://docs.astral.sh/uv/concepts/projects/sync/).
MkDocs prepara una copia explícita de la documentación en `.local/site-source`;
`site/` es un producto de construcción. Ninguno se publica automáticamente.

## Organización del seminario 3

Autoría: QRT Solutions.

La base del seminario 2 permanece en sus rutas originales para conservar las
referencias del catálogo, las copias de plataformas y los verificadores.
Las incorporaciones se agrupan en [seminario_3](../seminario_3/README.md):

- `aplicaciones/web/`: aplicación web de bitácora y editor en Vanilla HTML/CSS/JavaScript con Chart.js, empaquetado estático con scripts Node y configuración para Vercel.
- `aplicaciones/kpi-laboratorio/`: prototipo local interactivo en React, motor estadístico de diez KPI (`engine.mjs`), tests Node y vista autónoma `preview.html` con datos simulados.
- `integraciones/telegram/`: Edge Function y lógica de interacción para el bot de registro de motivos en Telegram.
- `integraciones/metatrader/`: exportador EA v3.40, scripts de inyección histórica M1, desbloqueo 24/7 y guías de conexión.
- `supabase/`: 12 referencias SQL de esquemas y verificaciones (no un proyecto CLI versionado), tres Edge Functions y receptor de telemetría.
- `ejemplos/`, `pruebas/`, `material/` y `guias/`: ejercicios, suites de verificación, material docente y guías paso a paso.

Estas carpetas contienen código operativo probado localmente con suites de tests en Node.js y verificaciones SQL con rollback en el entorno docente histórico. Dichas pruebas previas son **históricas y no certifican servicios actuales ni despliegues en instalaciones nuevas**: cada alumno debe desplegar y verificar en su propio proyecto y cuentas. El código compartido y las 17 estrategias institucionales conservan su ubicación canónica en `quant_agentic_swarm/strategies/`. `masterclass/` sigue siendo la presentación interactiva del seminario 2; el material docente de la nueva edición se aloja en `seminario_3/material/`.

MkDocs incorpora las guías nuevas a su árbol de documentación. Los validadores del laboratorio conservan su alcance; las suites de prueba de la web y de las funciones Edge se ejecutan mediante Node.js sobre sus respectivos componentes.
