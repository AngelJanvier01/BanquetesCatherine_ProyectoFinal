-- Evidencias directas para SQL Developer.
-- Ejecutar conectado como BANQUETES_CATHERINE despues de instalar datos.

-- SELECT, WHERE y ORDER BY.
SELECT nombre, precio AS precio_por_persona, categoria
FROM PLATILLO
WHERE activo = 'S'
ORDER BY precio DESC;

-- Catalogo de salones locales con datos de instalacion.
SELECT nombre, zona, capacidad_maxima, costo_renta, contacto_instalacion, foto_url
FROM SALON
WHERE convenio_activo = 'S'
ORDER BY capacidad_maxima;

-- Usuarios por rol, incluyendo CHEF.
SELECT rol, COUNT(*) AS total_usuarios
FROM USUARIO
WHERE activo = 'S'
GROUP BY rol
ORDER BY rol;

-- Funciones Oracle de String.
SELECT
    UPPER(nombre) AS nombre_mayusculas,
    LOWER(categoria) AS categoria_minusculas,
    SUBSTR(nombre, 1, 12) AS nombre_corto,
    LENGTH(nombre) AS longitud_nombre
FROM PLATILLO
WHERE ROWNUM <= 5;

-- Funciones Oracle de Date.
SELECT
    nombre_evento,
    fecha_evento,
    ADD_MONTHS(fecha_evento, -1) AS fecha_un_mes_antes,
    TRUNC(fecha_evento) - TRUNC(SYSDATE) AS dias_restantes
FROM PROYECTO_EVENTO
WHERE estatus = 'ACTIVO'
ORDER BY fecha_evento;

-- Funciones matematicas.
SELECT
    nombre_evento,
    total_estimado,
    ROUND(total_estimado / numero_invitados, 2) AS costo_por_invitado,
    CEIL(numero_invitados / 10) AS mesas_estimadas
FROM PROYECTO_EVENTO
WHERE estatus = 'ACTIVO';

-- Invitados y confirmaciones por proyecto.
SELECT pe.nombre_evento, inv.nombre, inv.correo, inv.estatus_confirmacion
FROM INVITADO_EVENTO inv
INNER JOIN PROYECTO_EVENTO pe ON pe.id_proyecto = inv.id_proyecto
ORDER BY pe.nombre_evento, inv.nombre;

-- INNER JOIN.
SELECT pe.nombre_evento, c.nombre || ' ' || c.apellido AS cliente, s.nombre AS salon
FROM PROYECTO_EVENTO pe
INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
INNER JOIN SALON s ON s.id_salon = pe.id_salon
ORDER BY pe.fecha_evento;

-- LEFT JOIN: platillos aunque no se hayan demandado.
SELECT pl.nombre, NVL(vp.proyectos_demandados, 0) AS proyectos_demandados
FROM PLATILLO pl
LEFT JOIN vw_popularidad_platillos vp ON vp.id_platillo = pl.id_platillo
ORDER BY proyectos_demandados DESC;

-- RIGHT JOIN: solicitudes con salon preferido, manteniendo todos los salones con convenio.
SELECT s.nombre AS salon, ss.id_solicitud, ss.nombre_contacto
FROM SOLICITUD_SERVICIO ss
RIGHT JOIN SALON s ON s.id_salon = ss.id_salon_preferido
WHERE s.convenio_activo = 'S'
ORDER BY s.nombre;

-- UNION: clientes y gerentes como personas del sistema sin duplicados.
SELECT nombre AS persona, 'CLIENTE' AS tipo FROM CLIENTE
UNION
SELECT nombre AS persona, 'GERENTE' AS tipo FROM GERENTE
ORDER BY persona;

-- UNION ALL: eventos activos y realizados conservando todos los registros.
SELECT nombre_evento, estatus FROM PROYECTO_EVENTO WHERE estatus = 'ACTIVO'
UNION ALL
SELECT nombre_evento, estatus FROM PROYECTO_EVENTO WHERE estatus = 'REALIZADO';

-- INTERSECT: clientes que tienen eventos activos y tambien realizados.
SELECT id_cliente FROM PROYECTO_EVENTO WHERE estatus = 'ACTIVO'
INTERSECT
SELECT id_cliente FROM PROYECTO_EVENTO WHERE estatus = 'REALIZADO';

-- MINUS: clientes registrados sin proyectos activos.
SELECT id_cliente FROM CLIENTE
MINUS
SELECT id_cliente FROM PROYECTO_EVENTO WHERE estatus = 'ACTIVO';

-- Vistas y funciones PL/SQL.
SELECT id_proyecto, nombre_evento, total_pagado, saldo_pendiente
FROM vw_estado_pago_proyecto
ORDER BY id_proyecto;

-- Paquetes armados con platillos y complementos existentes.
SELECT nombre, tipo_paquete, precio_base AS precio_por_persona, complementos_persona, complementos_evento, platillos, complementos
FROM vw_paquete_resumen
ORDER BY personalizado DESC, nombre;

-- Cotizacion calculada desde funcion PL/SQL.
SELECT
    fn_costo_paquete_persona(1) AS costo_persona_paquete,
    fn_complementos_evento_paquete(1) AS complementos_evento,
    fn_total_estimado_evento(120, 2, 1) AS total_estimado_evento
FROM dual;

SELECT
    id_proyecto,
    fn_total_pagado(id_proyecto) AS total_pagado_funcion,
    fn_saldo_pendiente(id_proyecto) AS saldo_pendiente_funcion,
    fn_dias_para_evento(id_proyecto) AS dias_para_evento
FROM PROYECTO_EVENTO
WHERE ROWNUM <= 5;

-- Vista de recetas para el chef.
SELECT platillo, dificultad, costo_estimado, nombre_ingrediente, cantidad, unidad_medida, instruccion
FROM vw_recetas_chef
WHERE ROWNUM <= 15
ORDER BY platillo, nombre_ingrediente;

-- DML controlado: INSERT, UPDATE, DELETE, SAVEPOINT, ROLLBACK, COMMIT y TRUNCATE.
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE tmp_evidencia_dml';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE tmp_evidencia_dml (
    id NUMBER PRIMARY KEY,
    descripcion VARCHAR2(100),
    monto NUMBER(10,2)
);

INSERT INTO tmp_evidencia_dml VALUES (1, 'Registro inicial', 100);
COMMIT;

SAVEPOINT antes_update;
UPDATE tmp_evidencia_dml
SET descripcion = 'Registro actualizado',
    monto = monto * 1.16
WHERE id = 1;

SELECT * FROM tmp_evidencia_dml;

ROLLBACK TO antes_update;
SELECT * FROM tmp_evidencia_dml;

SAVEPOINT antes_delete;
DELETE FROM tmp_evidencia_dml WHERE id = 1;
ROLLBACK TO antes_delete;

TRUNCATE TABLE tmp_evidencia_dml;
DROP TABLE tmp_evidencia_dml;

-- Procedimientos PL/SQL listos para demo.
-- Registrar pago:
-- BEGIN
--     sp_registrar_pago(2, 1000, 'ABONO', 'EFECTIVO', 'DEMO-ABONO-001');
-- END;
-- /

-- Cambio de invitados permitido para evento lejano del cliente.demo:
-- BEGIN
--     sp_actualizar_invitados(4, 1, 115);
-- END;
-- /

-- Cambio de invitados bloqueado por menos de 5 dias:
-- BEGIN
--     sp_actualizar_invitados(6, 3, 75);
-- END;
-- /

-- Registrar invitado desde PL/SQL:
-- DECLARE
--     v_id_invitado NUMBER;
-- BEGIN
--     sp_registrar_invitado(4, 1, 'Invitado SQL Developer', 'invitado.sql@example.com', '492-000-0000', v_id_invitado);
-- END;
-- /
