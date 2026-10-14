# Ayuda memoria — Presentación del 8 de octubre de 2026

Autoría: QRT Solutions · [www.qrtsolutions.com](https://www.qrtsolutions.com).

[Abrir versión HTML](html/ayuda-memoria.html) · Incluye modo presentación e impresión.

Guion de 15 minutos para mostrar lo construido. No hace falta reinstalar servicios
durante la presentación. Para reproducir la configuración después, entregar el
[resumen paso a paso](../guias/RESUMEN_CONFIGURACION.md) y el
[prompt para el agente](../guias/PROMPT_AGENTE.md).

## La frase de apertura

> MT5 registra lo que ocurrió; nosotros registramos por qué tomamos la decisión.
> Supabase conserva ambas cosas, Telegram facilita escribirlas y Vercel las muestra.

## Recorrido en pantalla

| Minutos | Mostrar / hacer | Qué explicar |
|---|---|---|
| 0–2 | Dashboard con datos de la demo | La web vive en Vercel; los datos, permisos y receptores viven en Supabase |
| 2–4 | Mapa de la configuración y funciones | Proyecto propio → SQL → receptor → clave de cuenta → EA → bot → web |
| 4–6 | Recepción reciente y HTTP 200, sin mostrar inputs secretos | El EA v3.40 se compiló, está activo y se verificó recepción; un binario por sí solo no prueba conexión |
| 6–9 | Una operación con apertura y cierre | Separar comentario nativo, motivo humano y resultado; aclarar qué textos son de muestra |
| 9–12 | En el bot: `/dashboard`; en la web: **Entrar con Telegram** | Copiar el código privadamente, editar un motivo elegido y mostrar su historial; no mostrar el código al público |
| 12–14 | Dashboard desde el celular o ventana estrecha | Misma información en tarjetas; lectura pública, edición solo del propietario |
| 14–15 | Resumen de instalación y prompt | Cada alumno crea sus recursos y verifica cada tramo con su agente |

Si no quieres modificar ningún motivo durante la presentación, muestra el editor
y su historial y cancela sin guardar. No es necesario abrir o cerrar un trade.

## Antes de compartir pantalla

- Abrir la URL de producción, el chat privado del bot y esta ayuda memoria.
- Comprobar recepción reciente con **Actualizar** y MT5 conectado.
- Tener elegida una operación existente; si es una muestra, decirlo al presentarla.
- Mantener fuera de la pantalla los inputs del EA, Secrets, `connection.json`,
  `.set` privados y códigos de acceso. No abrir esos archivos para explicar las claves.
- Probar el acceso al editor antes de la clase; no confundir pruebas del agente
  con una sesión de edición comprobada por el propietario.
- No compartir una URL Git heredada como si ya contuviera este trabajo: consultar
  [ENTREGA.md](../ENTREGA.md). La publicación Git del seminario 3 está pendiente.

## Los valores que no conviene confundir

| Recordatorio | Valor / explicación |
|---|---|
| Secret del bot | `TELEGRAM_BOT_TOKEN`, exactamente así |
| Nombre del proyecto en el EA | Debe coincidir con el registrado; `Seminario3` ≠ `Seminario-3` |
| Clave del EA | `mt5_…`: la genera nuestro script y luego se registra su hash |
| Clave de la web | `sb_publishable_…`: proviene de Supabase |
| WebRequest | URL base del proyecto Supabase |
| Cierre remoto | Siempre `false` |
| `/vincular` | Autoriza el chat; el código dura una hora y se usa una vez |
| `/dashboard` | Acceso al editor: código de cinco minutos; sesión de una hora |
| Actualización web | Estado 30 s, historial 2 min; botón **Actualizar** para consultar ahora |

## Comandos para tener a mano

| Comando o acción | Uso |
|---|---|
| `/pendientes` | Consultar hasta 20 operaciones recientes con motivos pendientes |
| Responder al aviso original | Completar el motivo de esa operación y fase |
| `/ver REFERENCIA` | Revisar los motivos de una operación |
| `/apertura REFERENCIA texto` | Registrar o corregir la entrada |
| `/cierre REFERENCIA texto` | Registrar o corregir la salida; no cierra un trade |
| `/dashboard` | Obtener código para editar en la web |
| `/protecciones` | Consultar cambios de SL/TP sin explicación |
| `/proteccion ID texto` | Registrar la explicación del cambio; no modifica MT5 |

## Preguntas habituales y respuesta breve

| Pregunta | Respuesta |
|---|---|
| ¿El dashboard vive en Supabase? | Vive en Vercel; consulta y guarda información a través de Supabase |
| ¿De dónde sale `mt5_`? | Del generador local del repositorio; autoriza una identidad concreta y vence por defecto a los 90 días |
| ¿Crear el bot basta? | No: faltan secreto, función, webhook y vinculación del propietario |
| ¿`/start` ya me autoriza? | No; la autorización se completa con `/vincular` |
| ¿Cualquiera puede editar? | La lectura de la demo es pública; escribir requiere acceso temporal del bot vinculado |
| ¿Puedo corregir un comentario del broker? | Esta aplicación conserva el original y permite corregir el motivo humano separado |
| ¿Si cierro MT5 sigue llegando información? | La nube conserva lo recibido; la telemetría nueva requiere MT5 y el EA funcionando |
| ¿Telegram mueve el stop? | No; documenta y explica los cambios observados |

## Qué está demostrado y qué no prometer

En el entorno docente se verificaron compilación v3.40 con **0 errores y
0 advertencias**, recepción real, dashboard público, vinculación del bot y motivos
guardados. Se verificó la interfaz móvil y existen pruebas controladas de edición
y protecciones. La primera sesión real de edición del propietario y el recorrido
completo de un cambio SL/TP con su motivo siguen sujetos a la evidencia del
[registro actual](../ESTADO.md); no presentarlos como certificados por los tests.

La muestra revisada tiene **102 operaciones**: se añadieron **199 motivos** de
muestra y se conservaron **cinco** del propietario. Después se abreviaron los
textos visibles a petición del docente. Su origen sintético queda en historial
y documentación: **no son evidencia de señales reales ni del razonamiento del trader**.
Los alumnos pueden usarlos para entender el formato, no para validar estrategias.

No prometer entrega instantánea, métricas MAE/MFE, equity histórica ni soporte
multiusuario completo. Los filtros y totales del historial se calculan en el
servidor; los gráficos y **Exportar página** corresponden solo a la página actual.

[Configuración resumida](../guias/RESUMEN_CONFIGURACION.md) ·
[Guion ampliado](README.md) · [Estado](../ESTADO.md).
