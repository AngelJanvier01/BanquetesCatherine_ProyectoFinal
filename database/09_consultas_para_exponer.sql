-- Consultas listas para exponer en SQLPlus o VS Code.
-- Ejecutar con: @database/09_consultas_para_exponer.sql

SET LINESIZE 220
SET PAGESIZE 120
COLUMN folio_proyecto FORMAT A12
COLUMN nombre_evento FORMAT A28
COLUMN cliente FORMAT A24
COLUMN salon FORMAT A32
COLUMN paquete FORMAT A26
COLUMN platillo FORMAT A32
COLUMN nombre FORMAT A32
COLUMN saldo_pendiente FORMAT 999,999,990.00
COLUMN total_estimado FORMAT 999,999,990.00
COLUMN total_pagado FORMAT 999,999,990.00

PROMPT ============================================================
PROMPT  1) Proyectos activos con folio, cliente, salon y saldo
PROMPT ============================================================
SELECT
    ep.folio_proyecto,
    pe.nombre_evento,
    c.nombre || ' ' || c.apellido AS cliente,
    s.nombre AS salon,
    ep.total_estimado,
    ep.total_pagado,
    ep.saldo_pendiente
FROM PROYECTO_EVENTO pe
INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
INNER JOIN SALON s ON s.id_salon = pe.id_salon
INNER JOIN vw_estado_pago_proyecto ep ON ep.id_proyecto = pe.id_proyecto
WHERE pe.estatus = 'ACTIVO'
ORDER BY pe.fecha_evento;

PROMPT ============================================================
PROMPT  2) Paquetes formados con platillos y complementos existentes
PROMPT ============================================================
SELECT
    nombre,
    tipo_paquete,
    precio_base AS precio_por_persona,
    complementos_persona,
    complementos_evento,
    platillos,
    complementos
FROM vw_paquete_resumen
ORDER BY personalizado DESC, nombre;

PROMPT ============================================================
PROMPT  3) Cotizacion desde funciones PL/SQL
PROMPT ============================================================
SELECT
    fn_costo_paquete_persona(1) AS costo_persona,
    fn_complementos_evento_paquete(1) AS complementos_evento,
    fn_total_estimado_evento(120, 2, 1) AS total_para_120_invitados
FROM dual;

PROMPT ============================================================
PROMPT  4) Cambio bloqueado por regla de 5 dias
PROMPT ============================================================
SELECT
    folio_proyecto,
    nombre_evento,
    fecha_evento,
    numero_invitados,
    puede_cambiar_invitados
FROM vw_proyectos_cliente
ORDER BY fecha_evento;

PROMPT ============================================================
PROMPT  5) Ingredientes necesarios para eventos proximos
PROMPT ============================================================
SELECT
    fecha_evento,
    nombre_ingrediente,
    unidad_medida,
    SUM(cantidad_necesaria) AS cantidad_necesaria
FROM vw_ingredientes_eventos
WHERE fecha_evento BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 14
GROUP BY fecha_evento, nombre_ingrediente, unidad_medida
ORDER BY fecha_evento, nombre_ingrediente;

PROMPT ============================================================
PROMPT  6) Eventos no finiquitados dentro de 21 dias
PROMPT ============================================================
SELECT
    folio_proyecto,
    nombre_evento,
    cliente,
    dias_restantes,
    total_estimado,
    total_pagado,
    saldo_pendiente
FROM vw_eventos_no_finiquitados_21
ORDER BY fecha_evento;

PROMPT ============================================================
PROMPT  7) Platillos mas populares y menos demandados
PROMPT ============================================================
SELECT
    platillo,
    categoria,
    proyectos_demandados,
    usos_realizados,
    usos_activos
FROM vw_popularidad_platillos
ORDER BY proyectos_demandados DESC, platillo;

PROMPT ============================================================
PROMPT  8) Historial de cliente
PROMPT ============================================================
SELECT
    cliente,
    folio_proyecto,
    nombre_evento,
    paquete,
    fecha_evento,
    total_estimado,
    estatus
FROM vw_historial_cliente
ORDER BY cliente, fecha_evento DESC;

PROMPT ============================================================
PROMPT  9) Operadores de conjunto: clientes con activos y realizados
PROMPT ============================================================
SELECT id_cliente FROM PROYECTO_EVENTO WHERE estatus = 'ACTIVO'
INTERSECT
SELECT id_cliente FROM PROYECTO_EVENTO WHERE estatus = 'REALIZADO';

PROMPT ============================================================
PROMPT  10) LEFT JOIN: platillos aunque no tengan demanda
PROMPT ============================================================
SELECT
    pl.nombre AS platillo,
    NVL(vp.proyectos_demandados, 0) AS proyectos_demandados
FROM PLATILLO pl
LEFT JOIN vw_popularidad_platillos vp ON vp.id_platillo = pl.id_platillo
ORDER BY proyectos_demandados DESC, pl.nombre;
