# Guion docente — Del trade a la bitácora en la nube

Autoría: QRT Solutions.

Material de apoyo al [recorrido del alumno](../guias/README.md). Este guion consolida
la sesión; no es una presentación de diapositivas ni reemplaza las guías técnicas.
La presentación del seminario anterior continúa en [masterclass](../../masterclass/index.html).

Para la sesión del 8 de octubre, abrir la [ayuda memoria de 15 minutos](AYUDA_MEMORIA.md).
El [resumen de configuración](../guias/RESUMEN_CONFIGURACION.md) reúne los pasos
que los alumnos reproducen después con su agente.

## Dos HTML para abrir y compartir

- [Configuración paso a paso](html/configuracion.html).
- [Ayuda memoria de la presentación](html/ayuda-memoria.html).

Abre los archivos con un navegador y conserva ambos en la misma carpeta para
usar los enlaces entre ellos. Incluyen estilos, controles y referencias directas
sin dependencias externas: el contenido se lee sin conexión. Los enlaces a las
páginas oficiales requieren internet. Las referencias más profundas indican el
archivo que se consulta en el repositorio.

Tienen índice, tablas adaptadas al celular, copia de comandos, modo presentación
y botón **Imprimir / PDF**. La impresión incluye el documento principal; las
referencias desplegables se consultan en pantalla. No contienen credenciales ni
consultan datos de trading. Son copias de la documentación al generarlas.

Para actualizarlos después de editar las fuentes Markdown, desde la raíz:

```sh
# Autor: QRT Solutions
uv run --locked python tools/build_seminario3_handouts.py
```

El generador usa Markdown del entorno de documentación. Verifica ambas versiones
en navegador después de regenerar; no edites el HTML generado como fuente canónica.

| Bloque | Demostración | Aprendizaje observable |
|---|---|---|
| 1. Arquitectura | Dibujar MT5 → Supabase → Vercel y el circuito Telegram | El alumno ubica datos, interfaz y agente |
| 2. Preparación | Leer el clon y detectar conectores | Distingue infraestructura existente de componentes faltantes |
| 3. Identidad y credenciales | Generar token restringido sin mostrarlo | Explica por qué una contraseña administrativa no va en el EA |
| 4. Recepción | Contrastar snapshot, HTTP y `received_at` | No confunde compilación con integración funcionando |
| 5. Dashboard | Leer posiciones, deals y comentarios | Diferencia ejecución, posición, resultado monetario y motivo |
| 6. Telegram | Crear bot, guardar secreto, vincular chat y responder aviso | Comprende que crear el bot no instala su programa y `/start` no autoriza |
| 7. Edición | Entrar con código, corregir motivo y consultar historial | Comprueba lectura pública y escritura restringida |
| 8. Reproducción | Ejecutar pruebas y llenar el registro privado | Declara evidencia y pendientes sin copiar secretos del docente |

## Preparación del docente

- Usar una demo, comprobar WebRequest, receptor y vinculación antes de la clase.
- Ocultar tokens y pantallas de Secrets al compartir pantalla.
- Distinguir los motivos reales de los textos de muestra: los 199 motivos breves
  añadidos para la presentación conservan su procedencia sintética en la auditoría.
- Tener una operación histórica propia disponible si no se hará trading durante la clase.
- Explicar que los avisos dependen de eventos y red; no prometer instantaneidad.
- Entregar la URL del repositorio que realmente contenga esta versión, tras publicar
  siguiendo [ENTREGA.md](../ENTREGA.md).

## Preguntas para cerrar la sesión

1. ¿Dónde viven los datos si Vercel deja de servir la web?
2. ¿Por qué `/start` y `/vincular` cumplen funciones diferentes?
3. ¿Qué diferencia hay entre comentario del EA y motivo humano?
4. ¿Qué evita sobrescribir una edición hecha desde otra ventana?
5. ¿Qué métricas no podemos calcular con esta telemetría y por qué?
6. ¿Qué evidencia falta para declarar que otro alumno completó la instalación?

[Ejercicios](../ejemplos/README.md) · [Estado y límites](../ESTADO.md).
