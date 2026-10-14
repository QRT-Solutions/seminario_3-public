# Verificación del laboratorio KPI

Autoría: QRT Solutions. Fecha: 8 de octubre de 2026.

| Control | Resultado |
|---|---|
| Motor estadístico | Ocho pruebas aprobadas: valores conocidos, dirección, cobertura, parciales, neutros, rachas, duplicados, filtros, variación nula, denominadores cero y anualización |
| Datos de demostración | 48 operaciones analizables, una incompleta excluida y 40 retornos diarios ficticios |
| Tarjetas iniciales | Diez visibles; tasa de acierto 50%, Profit Factor % 2,42, Payoff 2,01; contraste con fixture y motor |
| Filtro EURUSD | 16 analizables, 12 perdedoras y 4 neutras; Payoff no disponible; las métricas de cuenta no cambian |
| Periodo vacío | Diez tarjetas sin valores inventados |
| Restablecer | Recupera las 48 operaciones y la exclusión inicial |
| Gráficos | Curvas de retorno acumulado y drawdown pintadas e inspeccionadas en navegador |
| Anchos 1440 y 390 | Cuatro y dos columnas de operaciones, respectivamente; sin desbordamiento horizontal de página |
| Consola | Sin errores observados en la revisión del prototipo |
| Entrega | HTML autónomo, motor puro, fixture, pruebas, fuente visual y guía de activación |
| Servicios externos | Sin migraciones, cambios de datos, compilación MT5 ni despliegue Vercel |

Las comprobaciones se hicieron con datos simulados. No validan la reconstrucción
de posiciones reales, el ajuste de flujos ni la cobertura histórica de la cuenta.
Esos adaptadores permanecen pendientes para el seminario.

[Volver al laboratorio](README.md).
