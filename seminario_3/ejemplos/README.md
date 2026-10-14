# Ejercicios guiados del seminario 3

Autoría: QRT Solutions.

Los ejercicios usan la instalación propia del alumno. No requieren copiar datos
del docente. Los ejemplos de razones son ilustrativos, no señales de trading:
solo se registra la explicación real del propietario cuando corresponde.

## Ejercicio 1 — Seguir un dato hasta la nube

Objetivo: distinguir compilación, envío y lectura.

1. Completa MT5 → Supabase sin abrir nuevas operaciones.
2. Anota localmente el `received_at` del snapshot.
3. Espera otro latido y comprueba que avance, conservando una fila de snapshot.
4. Contrasta balance y número de posiciones con MT5 y con el dashboard.

Resultado esperado: puedes explicar qué componente produjo cada valor y detectar
una lectura atrasada. Una cuenta sin posiciones puede completar este ejercicio.

## Ejercicio 2 — Reconocer comentarios y motivos

Objetivo: separar información de la plataforma e intención del operador.

1. Elige una operación propia ya recibida.
2. Revisa los comentarios nativos y si existe motivo de apertura/cierre.
3. Identifica qué campo proviene de MT5 y cuál escribió una persona.
4. Si no conoces la razón, conserva «pendiente»; no la inventes para llenar la tabla.

Ejemplo de redacción cuando sea verdadero: «Entrada tras confirmar ruptura al cierre
de vela». Un texto como «EA_MEDIA_01» puede ser una etiqueta técnica, no una razón
completa. `magic` tampoco sustituye esa explicación.

## Ejercicio 3 — Responder al aviso correcto

Objetivo: asociar el mensaje con la operación y la fase correctas.

1. Vincula el chat y comprueba `/pendientes`.
2. Si el propietario decide por su cuenta operar en demo, espera su aviso de apertura.
3. Pulsa **Responder** sobre ese mensaje y escribe la razón real.
4. Consulta `/ver REFERENCIA` y revisa la columna de apertura en la web.
5. Si el propietario cierra o reduce la operación, responde al aviso de cierre y
   verifica que el motivo de apertura permanezca intacto.

El agente no ejecuta operaciones para este ejercicio. Como alternativa, utiliza
los comandos `/apertura` y `/cierre` en una operación propia existente cuya fase
haya sido recibida. Los avisos no se regeneran por reenviar todo el histórico.

## Ejercicio 4 — Corregir desde el dashboard

Objetivo: utilizar el mismo registro desde dos canales.

1. Envía `/dashboard` al bot y usa el código en **Entrar con Telegram**.
2. Edita una explicación propia que realmente necesite corrección y guarda.
3. Consulta el historial para ver el texto anterior.
4. Comprueba el motivo vigente desde Telegram y desde una ventana pública.
5. Pulsa **Salir de edición**; la lectura debe continuar sin botones para guardar.

En un proyecto exclusivo de práctica puedes comprobar un conflicto: abre el mismo
motivo en dos ventanas autorizadas, guarda una corrección en la primera y trata de
guardar desde la segunda. Debe avisar del cambio y conservar el borrador.
No hagas esta prueba sobre razones ajenas ni publiques ejemplos ficticios como trades reales.

## Entrega del ejercicio

Presenta pasos, comprobaciones y límites sin credenciales ni identificadores de
cuenta. Usa la [plantilla de instalación](../guias/REGISTRO_INSTALACION.md) para la
parte privada y el [plan de pruebas](../pruebas/README.md) para distinguir evidencias.

[Volver al seminario](../README.md).
