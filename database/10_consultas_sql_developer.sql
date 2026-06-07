-- Consultas listas para exposicion en SQL Developer.
-- Autores: Angel Janvier Gonzalez Delgado y Carlos Alberto Gutierrez Flores.
-- Conexion recomendada:
-- Usuario: BANQUETES_CATHERINE
-- Password: Catherine2026
-- Si falla conexion Basic con ORA-12518, usa Connection Type: Advanced
-- Custom JDBC URL:
-- jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=SHARED)(SERVICE_NAME=xepdb1)))

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

-- 1. Confirmar usuario y esquema conectado.
SELECT
    USER AS usuario_conectado,
    SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS servicio,
    SYSDATE AS fecha_servidor
FROM dual;

-- 2. Evidencia de tablas del proyecto.
SELECT table_name
FROM user_tables
ORDER BY table_name;

-- 3. Evidencia de secuencias.
SELECT sequence_name, last_number
FROM user_sequences
ORDER BY sequence_name;

-- 4. Evidencia de vistas, funciones, procedimientos y sinonimos.
SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('VIEW', 'FUNCTION', 'PROCEDURE', 'SYNONYM')
ORDER BY object_type, object_name;

-- 5. Proyectos activos con folio, cliente, salon y saldo.
SELECT
    folio_proyecto,
    nombre_evento,
    cliente,
    salon,
    numero_invitados,
    total_estimado,
    total_pagado,
    saldo_pendiente
FROM vw_proyectos_cliente
WHERE estatus = 'ACTIVO'
ORDER BY fecha_evento;

-- 6. Cobranza: eventos no finiquitados dentro de 21 dias.
SELECT
    folio_proyecto,
    nombre_evento,
    cliente,
    dias_restantes,
    total_estimado,
    total_pagado,
    saldo_pendiente
FROM vw_eventos_no_finiquitados_21
ORDER BY dias_restantes;

-- 7. Ingredientes necesarios para eventos proximos.
-- Las recetas son por persona; el reporte multiplica por numero de invitados.
SELECT
    fecha_evento,
    nombre_evento,
    nombre_ingrediente,
    unidad_medida,
    cantidad_necesaria
FROM vw_ingredientes_eventos
WHERE fecha_evento BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 14
ORDER BY fecha_evento, nombre_ingrediente;

-- 8. Platillos mas populares y menos demandados.
SELECT
    platillo,
    categoria,
    proyectos_demandados,
    usos_realizados,
    usos_activos
FROM vw_popularidad_platillos
ORDER BY proyectos_demandados DESC, platillo;

-- 9. Historial de cliente.
SELECT
    cliente,
    folio_proyecto,
    nombre_evento,
    paquete,
    fecha_evento,
    total_estimado,
    estatus
FROM vw_historial_cliente
ORDER BY cliente, fecha_evento;

-- 10. Funcion PL/SQL: cotizar evento.
SELECT
    fn_total_estimado_evento(120, 2, 1) AS total_evento_120_personas,
    fn_saldo_pendiente(3) AS saldo_proyecto_3,
    CASE
        WHEN fn_dias_para_evento(3) >= 5 THEN 'S'
        ELSE 'N'
    END AS puede_cambiar_invitados
FROM dual;

-- 11. JOIN: solicitud separada de proyecto.
SELECT
    ss.id_solicitud,
    ss.nombre_contacto,
    ss.estatus AS estatus_solicitud,
    CASE
        WHEN pe.id_proyecto IS NULL THEN 'SIN PROYECTO'
        ELSE 'BC-' || LPAD(pe.id_proyecto, 5, '0')
    END AS folio_proyecto,
    pe.estatus AS estatus_proyecto
FROM solicitud_servicio ss
LEFT JOIN proyecto_evento pe ON pe.id_solicitud = ss.id_solicitud
ORDER BY ss.id_solicitud;

-- 12. Operador de conjunto INTERSECT: clientes con eventos activos y realizados.
SELECT id_cliente
FROM proyecto_evento
WHERE estatus = 'ACTIVO'
INTERSECT
SELECT id_cliente
FROM proyecto_evento
WHERE estatus = 'REALIZADO';

-- 13. Operador de conjunto MINUS: platillos sin demanda.
SELECT nombre
FROM platillo
MINUS
SELECT pl.nombre
FROM platillo pl
INNER JOIN paquete_platillo pp ON pp.id_platillo = pl.id_platillo
INNER JOIN proyecto_evento pe ON pe.id_paquete = pp.id_paquete;

-- 14. Validacion de recetas por persona.
SELECT
    COUNT(*) AS platillos_fuera_de_regla
FROM platillo
WHERE porciones_base <> 1;

-- 15. Recetario publico: publicaciones con conteo de ingredientes y pasos.
SELECT
    titulo_publico,
    categoria,
    dificultad,
    destacado,
    numero_ingredientes,
    numero_pasos
FROM vw_recetario_publico
ORDER BY destacado DESC, titulo_publico;

-- 16. Receta compartida: publicacion, platillo base, ingredientes e instrucciones.
SELECT
    r.titulo_publico,
    i.nombre_ingrediente,
    pi.cantidad,
    i.unidad_medida,
    inst.numero_paso,
    inst.instruccion
FROM vw_recetario_publico r
INNER JOIN platillo_ingrediente pi ON pi.id_platillo = r.id_platillo
INNER JOIN ingrediente i ON i.id_ingrediente = pi.id_ingrediente
LEFT JOIN instruccion inst ON inst.id_platillo = r.id_platillo
WHERE r.destacado = 'S'
ORDER BY r.titulo_publico, i.nombre_ingrediente, inst.numero_paso;
