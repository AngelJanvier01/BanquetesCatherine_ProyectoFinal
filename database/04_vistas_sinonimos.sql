-- Vistas para catalogos publicos, paneles y reportes.

CREATE OR REPLACE VIEW vw_platillos_publicos AS
SELECT
    pl.id_platillo,
    INITCAP(pl.nombre) AS nombre,
    pl.descripcion,
    pl.precio,
    pl.costo_estimado,
    pl.porciones_base,
    pl.categoria,
    pl.tipo_dieta,
    pl.dificultad,
    pl.foto_url,
    (
        SELECT COUNT(1)
        FROM PLATILLO_INGREDIENTE pi
        WHERE pi.id_platillo = pl.id_platillo
    ) AS numero_ingredientes
FROM PLATILLO pl
WHERE pl.activo = 'S';

CREATE OR REPLACE VIEW vw_complementos_publicos AS
SELECT
    id_complemento,
    INITCAP(nombre) AS nombre,
    descripcion,
    precio,
    tipo_complemento,
    tipo_cobro
FROM COMPLEMENTO
WHERE activo = 'S';

CREATE OR REPLACE VIEW vw_salones_publicos AS
SELECT
    id_salon,
    INITCAP(nombre) AS nombre,
    direccion,
    zona,
    descripcion,
    foto_url,
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
    precio_base,
    tipo_paquete,
    margen_ganancia
FROM PAQUETE
WHERE activo = 'S'
  AND visible_publico = 'S'
  AND personalizado = 'N';

CREATE OR REPLACE VIEW vw_paquete_resumen AS
SELECT
    p.id_paquete,
    p.nombre,
    p.descripcion,
    p.precio_base,
    p.tipo_paquete,
    p.margen_ganancia,
    p.visible_publico,
    p.personalizado,
    p.id_cliente,
    NVL((
        SELECT SUM(pl.costo_estimado * pp.cantidad)
        FROM PAQUETE_PLATILLO pp
        INNER JOIN PLATILLO pl ON pl.id_platillo = pp.id_platillo
        WHERE pp.id_paquete = p.id_paquete
    ), 0) AS costo_platillos_persona,
    NVL((
        SELECT SUM(CASE WHEN c.tipo_cobro = 'POR_PERSONA' THEN c.precio * pc.cantidad ELSE 0 END)
        FROM PAQUETE_COMPLEMENTO pc
        INNER JOIN COMPLEMENTO c ON c.id_complemento = pc.id_complemento
        WHERE pc.id_paquete = p.id_paquete
    ), 0) AS complementos_persona,
    NVL((
        SELECT SUM(CASE WHEN c.tipo_cobro = 'POR_EVENTO' THEN c.precio * pc.cantidad ELSE 0 END)
        FROM PAQUETE_COMPLEMENTO pc
        INNER JOIN COMPLEMENTO c ON c.id_complemento = pc.id_complemento
        WHERE pc.id_paquete = p.id_paquete
    ), 0) AS complementos_evento,
    NVL((
        SELECT LISTAGG(pl.nombre, ', ') WITHIN GROUP (ORDER BY pl.nombre)
        FROM PAQUETE_PLATILLO pp
        INNER JOIN PLATILLO pl ON pl.id_platillo = pp.id_platillo
        WHERE pp.id_paquete = p.id_paquete
    ), 'Sin platillos') AS platillos,
    NVL((
        SELECT LISTAGG(c.nombre, ', ') WITHIN GROUP (ORDER BY c.nombre)
        FROM PAQUETE_COMPLEMENTO pc
        INNER JOIN COMPLEMENTO c ON c.id_complemento = pc.id_complemento
        WHERE pc.id_paquete = p.id_paquete
    ), 'Sin complementos') AS complementos
FROM PAQUETE p
WHERE p.activo = 'S';

CREATE OR REPLACE VIEW vw_paquete_platillos AS
SELECT
    pp.id_paquete,
    pp.id_platillo,
    pl.nombre AS platillo,
    pp.cantidad,
    pl.precio,
    pl.costo_estimado,
    pl.categoria
FROM PAQUETE_PLATILLO pp
INNER JOIN PLATILLO pl ON pl.id_platillo = pp.id_platillo;

CREATE OR REPLACE VIEW vw_paquete_complementos AS
SELECT
    pc.id_paquete,
    pc.id_complemento,
    c.nombre AS complemento,
    pc.cantidad,
    c.precio,
    c.tipo_complemento,
    c.tipo_cobro
FROM PAQUETE_COMPLEMENTO pc
INNER JOIN COMPLEMENTO c ON c.id_complemento = pc.id_complemento;

CREATE OR REPLACE VIEW vw_estado_pago_proyecto AS
SELECT
    pe.id_proyecto,
    'BC-' || LPAD(pe.id_proyecto, 5, '0') AS folio_proyecto,
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
    'BC-' || LPAD(pe.id_proyecto, 5, '0') AS folio_proyecto,
    pe.nombre_evento,
    pe.fecha_evento,
    pe.numero_invitados,
    pe.id_salon,
    pe.id_paquete,
    s.nombre AS salon,
    s.direccion AS direccion_salon,
    s.contacto_instalacion,
    s.telefono_contacto,
    p.nombre AS paquete,
    pr.platillos,
    pr.complementos,
    pe.estatus,
    ep.total_estimado,
    ep.total_pagado,
    ep.saldo_pendiente,
    ep.porcentaje_pagado,
    ROUND(pe.total_estimado / NULLIF(pe.numero_invitados, 0), 2) AS costo_por_persona,
    CASE
        WHEN TRUNC(pe.fecha_evento) - TRUNC(SYSDATE) >= 5 THEN 'S'
        ELSE 'N'
    END AS puede_cambiar_invitados
FROM CLIENTE c
INNER JOIN USUARIO u ON u.id_usuario = c.id_usuario
INNER JOIN PROYECTO_EVENTO pe ON pe.id_cliente = c.id_cliente
INNER JOIN SALON s ON s.id_salon = pe.id_salon
INNER JOIN PAQUETE p ON p.id_paquete = pe.id_paquete
INNER JOIN vw_paquete_resumen pr ON pr.id_paquete = p.id_paquete
INNER JOIN vw_estado_pago_proyecto ep ON ep.id_proyecto = pe.id_proyecto;

CREATE OR REPLACE VIEW vw_solicitudes_pendientes AS
SELECT
    ss.id_solicitud,
    'SOL-' || LPAD(ss.id_solicitud, 5, '0') AS folio_solicitud,
    ss.nombre_contacto,
    ss.correo,
    ss.telefono,
    ss.fecha_evento,
    ss.numero_invitados,
    NVL(s.nombre, 'SIN PREFERENCIA') AS salon_preferido,
    ss.id_salon_preferido,
    NVL(p.nombre, 'SIN PREFERENCIA') AS paquete_preferido,
    ss.id_paquete_preferido,
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
    SUM(pi.cantidad * pp.cantidad * pe.numero_invitados) AS cantidad_necesaria
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
    'BC-' || LPAD(pe.id_proyecto, 5, '0') AS folio_proyecto,
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
    'BC-' || LPAD(pe.id_proyecto, 5, '0') AS folio_proyecto,
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

CREATE OR REPLACE VIEW vw_invitados_proyecto AS
SELECT
    inv.id_invitado,
    inv.id_proyecto,
    inv.nombre,
    inv.correo,
    inv.telefono,
    inv.estatus_confirmacion,
    inv.fecha_invitacion,
    inv.fecha_respuesta,
    pe.id_cliente
FROM INVITADO_EVENTO inv
INNER JOIN PROYECTO_EVENTO pe ON pe.id_proyecto = inv.id_proyecto;

CREATE OR REPLACE VIEW vw_cortesias_cliente AS
SELECT
    ce.id_cortesia,
    ce.id_proyecto,
    pe.id_cliente,
    ce.tipo_cortesia,
    ce.titulo,
    ce.detalle,
    ce.estatus,
    ce.fecha_registro
FROM CORTESIA_EVENTO ce
INNER JOIN PROYECTO_EVENTO pe ON pe.id_proyecto = ce.id_proyecto;

CREATE OR REPLACE VIEW vw_recetas_chef AS
SELECT
    pl.id_platillo,
    pl.nombre AS platillo,
    pl.descripcion,
    pl.categoria,
    pl.precio,
    pl.costo_estimado,
    pl.dificultad,
    pl.porciones_base,
    pl.foto_url,
    i.id_ingrediente,
    i.nombre_ingrediente,
    i.unidad_medida,
    pi.cantidad,
    inst.numero_paso,
    inst.instruccion,
    inst.detalle_instruccion
FROM PLATILLO pl
LEFT JOIN PLATILLO_INGREDIENTE pi ON pi.id_platillo = pl.id_platillo
LEFT JOIN INGREDIENTE i ON i.id_ingrediente = pi.id_ingrediente
LEFT JOIN INSTRUCCION inst ON inst.id_platillo = pl.id_platillo
WHERE pl.activo = 'S';

CREATE OR REPLACE SYNONYM cat_platillos FOR vw_platillos_publicos;
CREATE OR REPLACE SYNONYM cat_complementos FOR vw_complementos_publicos;
CREATE OR REPLACE SYNONYM cat_salones FOR vw_salones_publicos;
CREATE OR REPLACE SYNONYM rep_cobranza FOR vw_eventos_no_finiquitados_21;
CREATE OR REPLACE SYNONYM rep_popularidad FOR vw_popularidad_platillos;
CREATE OR REPLACE SYNONYM rep_recetas FOR vw_recetas_chef;
