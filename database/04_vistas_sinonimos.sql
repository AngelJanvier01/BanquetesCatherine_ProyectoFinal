-- Vistas para catalogos publicos y reportes.

CREATE OR REPLACE VIEW vw_platillos_publicos AS
SELECT
    id_platillo,
    INITCAP(nombre) AS nombre,
    descripcion,
    precio,
    porciones_base,
    categoria,
    tipo_dieta
FROM PLATILLO
WHERE activo = 'S';

CREATE OR REPLACE VIEW vw_complementos_publicos AS
SELECT
    id_complemento,
    INITCAP(nombre) AS nombre,
    descripcion,
    precio
FROM COMPLEMENTO
WHERE activo = 'S';

CREATE OR REPLACE VIEW vw_salones_publicos AS
SELECT
    id_salon,
    INITCAP(nombre) AS nombre,
    direccion,
    costo_renta,
    capacidad_maxima,
    contacto_instalacion,
    telefono_contacto,
    correo_contacto
FROM SALON
WHERE activo = 'S'
  AND convenio_activo = 'S';

CREATE OR REPLACE VIEW vw_paquetes_publicos AS
SELECT
    id_paquete,
    INITCAP(nombre) AS nombre,
    descripcion,
    precio_base
FROM PAQUETE
WHERE activo = 'S'
  AND visible_publico = 'S'
  AND personalizado = 'N';

CREATE OR REPLACE VIEW vw_estado_pago_proyecto AS
SELECT
    pe.id_proyecto,
    pe.nombre_evento,
    pe.fecha_evento,
    pe.estatus,
    pe.finiquitado,
    pe.total_estimado,
    NVL(SUM(pg.monto), 0) AS total_pagado,
    GREATEST(pe.total_estimado - NVL(SUM(pg.monto), 0), 0) AS saldo_pendiente,
    ROUND((NVL(SUM(pg.monto), 0) / NULLIF(pe.total_estimado, 0)) * 100, 2) AS porcentaje_pagado
FROM PROYECTO_EVENTO pe
LEFT JOIN PAGO pg ON pg.id_proyecto = pe.id_proyecto
GROUP BY
    pe.id_proyecto,
    pe.nombre_evento,
    pe.fecha_evento,
    pe.estatus,
    pe.finiquitado,
    pe.total_estimado;

CREATE OR REPLACE VIEW vw_proyectos_cliente AS
SELECT
    c.id_cliente,
    u.id_usuario,
    u.nombre_usuario,
    c.nombre || ' ' || c.apellido AS cliente,
    pe.id_proyecto,
    pe.nombre_evento,
    pe.fecha_evento,
    pe.numero_invitados,
    s.nombre AS salon,
    p.nombre AS paquete,
    pe.estatus,
    ep.total_estimado,
    ep.total_pagado,
    ep.saldo_pendiente,
    ep.porcentaje_pagado,
    CASE
        WHEN TRUNC(pe.fecha_evento) - TRUNC(SYSDATE) >= 5 THEN 'S'
        ELSE 'N'
    END AS puede_cambiar_invitados
FROM CLIENTE c
INNER JOIN USUARIO u ON u.id_usuario = c.id_usuario
INNER JOIN PROYECTO_EVENTO pe ON pe.id_cliente = c.id_cliente
INNER JOIN SALON s ON s.id_salon = pe.id_salon
INNER JOIN PAQUETE p ON p.id_paquete = pe.id_paquete
INNER JOIN vw_estado_pago_proyecto ep ON ep.id_proyecto = pe.id_proyecto;

CREATE OR REPLACE VIEW vw_solicitudes_pendientes AS
SELECT
    ss.id_solicitud,
    ss.nombre_contacto,
    ss.correo,
    ss.telefono,
    ss.fecha_evento,
    ss.numero_invitados,
    NVL(s.nombre, 'SIN PREFERENCIA') AS salon_preferido,
    NVL(p.nombre, 'SIN PREFERENCIA') AS paquete_preferido,
    ss.mensaje,
    ss.estatus,
    ss.fecha_solicitud,
    ss.origen
FROM SOLICITUD_SERVICIO ss
LEFT JOIN SALON s ON s.id_salon = ss.id_salon_preferido
LEFT JOIN PAQUETE p ON p.id_paquete = ss.id_paquete_preferido
WHERE ss.estatus = 'PENDIENTE';

CREATE OR REPLACE VIEW vw_salones_alternativos AS
SELECT
    id_salon,
    nombre,
    capacidad_maxima,
    costo_renta,
    contacto_instalacion,
    telefono_contacto,
    correo_contacto
FROM SALON
WHERE activo = 'S'
  AND convenio_activo = 'S';

CREATE OR REPLACE VIEW vw_ingredientes_eventos AS
SELECT
    TRUNC(pe.fecha_evento) AS fecha_evento,
    pe.id_proyecto,
    pe.nombre_evento,
    i.id_ingrediente,
    i.nombre_ingrediente,
    i.unidad_medida,
    SUM(pi.cantidad * pp.cantidad * CEIL(pe.numero_invitados / pl.porciones_base)) AS cantidad_necesaria
FROM PROYECTO_EVENTO pe
INNER JOIN PAQUETE p ON p.id_paquete = pe.id_paquete
INNER JOIN PAQUETE_PLATILLO pp ON pp.id_paquete = p.id_paquete
INNER JOIN PLATILLO pl ON pl.id_platillo = pp.id_platillo
INNER JOIN PLATILLO_INGREDIENTE pi ON pi.id_platillo = pl.id_platillo
INNER JOIN INGREDIENTE i ON i.id_ingrediente = pi.id_ingrediente
WHERE pe.estatus IN ('ACTIVO', 'REALIZADO')
GROUP BY
    TRUNC(pe.fecha_evento),
    pe.id_proyecto,
    pe.nombre_evento,
    i.id_ingrediente,
    i.nombre_ingrediente,
    i.unidad_medida;

CREATE OR REPLACE VIEW vw_eventos_no_finiquitados_21 AS
SELECT
    pe.id_proyecto,
    pe.nombre_evento,
    c.nombre || ' ' || c.apellido AS cliente,
    c.telefono,
    c.correo,
    pe.fecha_evento,
    TRUNC(pe.fecha_evento) - TRUNC(SYSDATE) AS dias_restantes,
    ep.total_estimado,
    ep.total_pagado,
    ep.saldo_pendiente
FROM PROYECTO_EVENTO pe
INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
INNER JOIN vw_estado_pago_proyecto ep ON ep.id_proyecto = pe.id_proyecto
WHERE pe.estatus = 'ACTIVO'
  AND pe.finiquitado = 'N'
  AND TRUNC(pe.fecha_evento) BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 21
  AND ep.saldo_pendiente > 0;

CREATE OR REPLACE VIEW vw_popularidad_platillos AS
SELECT
    pl.id_platillo,
    pl.nombre AS platillo,
    pl.categoria,
    COUNT(DISTINCT pe.id_proyecto) AS proyectos_demandados,
    SUM(CASE WHEN pe.estatus = 'REALIZADO' THEN 1 ELSE 0 END) AS usos_realizados,
    SUM(CASE WHEN pe.estatus = 'ACTIVO' THEN 1 ELSE 0 END) AS usos_activos
FROM PLATILLO pl
LEFT JOIN PAQUETE_PLATILLO pp ON pp.id_platillo = pl.id_platillo
LEFT JOIN PROYECTO_EVENTO pe
    ON pe.id_paquete = pp.id_paquete
   AND pe.estatus IN ('ACTIVO', 'REALIZADO')
GROUP BY pl.id_platillo, pl.nombre, pl.categoria;

CREATE OR REPLACE VIEW vw_historial_cliente AS
SELECT
    c.id_cliente,
    c.nombre || ' ' || c.apellido AS cliente,
    pe.id_proyecto,
    pe.nombre_evento,
    pe.fecha_evento,
    pa.nombre AS paquete,
    LISTAGG(pl.nombre, ', ') WITHIN GROUP (ORDER BY pl.nombre) AS platillos,
    pe.numero_invitados,
    pe.estatus,
    ep.total_estimado,
    ep.total_pagado,
    ep.saldo_pendiente
FROM CLIENTE c
INNER JOIN PROYECTO_EVENTO pe ON pe.id_cliente = c.id_cliente
INNER JOIN PAQUETE pa ON pa.id_paquete = pe.id_paquete
INNER JOIN PAQUETE_PLATILLO pp ON pp.id_paquete = pa.id_paquete
INNER JOIN PLATILLO pl ON pl.id_platillo = pp.id_platillo
INNER JOIN vw_estado_pago_proyecto ep ON ep.id_proyecto = pe.id_proyecto
GROUP BY
    c.id_cliente,
    c.nombre,
    c.apellido,
    pe.id_proyecto,
    pe.nombre_evento,
    pe.fecha_evento,
    pa.nombre,
    pe.numero_invitados,
    pe.estatus,
    ep.total_estimado,
    ep.total_pagado,
    ep.saldo_pendiente;

-- Sinonimos privados para evidenciar el tema y facilitar consultas en demo.
CREATE OR REPLACE SYNONYM cat_platillos FOR vw_platillos_publicos;
CREATE OR REPLACE SYNONYM cat_complementos FOR vw_complementos_publicos;
CREATE OR REPLACE SYNONYM cat_salones FOR vw_salones_publicos;
CREATE OR REPLACE SYNONYM rep_cobranza FOR vw_eventos_no_finiquitados_21;
CREATE OR REPLACE SYNONYM rep_popularidad FOR vw_popularidad_platillos;
