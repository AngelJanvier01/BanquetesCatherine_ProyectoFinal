-- ============================================================================
-- PROYECTO FINAL SISTEMAS DE BASE DE DATOS II
-- BANQUETES CATHERINE
-- Archivo maestro para hoja de trabajo en Oracle SQL Developer.
--
-- Conexion recomendada:
-- Usuario: BANQUETES_CATHERINE
-- Password: Catherine2026
-- Tipo de conexion: JDBC personalizado / Advanced
-- URL:
-- jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=SHARED)(SERVICE_NAME=xepdb1)))
--
-- USO EN CLASE:
-- 1. Para reinstalar todo el esquema demo, ejecuta el archivo completo con F5.
-- 2. Para solo demostrar, selecciona una consulta o bloque y usa Ctrl+Enter.
-- 3. La limpieza solo borra objetos del esquema BANQUETES_CATHERINE.
-- 4. Las recetas, platillos, paquetes y costos se manejan por persona.
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;
SET PAGESIZE 200;
SET LINESIZE 220;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

SELECT
    USER AS usuario_conectado,
    SYSDATE AS fecha_ejecucion
FROM dual;


-- ============================================================================
-- 00 LIMPIEZA SEGURA DEL ESQUEMA
-- Archivo fuente: database\00_drop_schema_objects.sql
-- ============================================================================

-- Limpieza segura: ejecutar conectado como BANQUETES_CATHERINE.
-- No elimina usuarios ni objetos fuera del esquema actual.

BEGIN
    FOR obj IN (
        SELECT owner, object_name, object_type
        FROM all_objects
        WHERE owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
          AND object_type IN ('VIEW', 'SYNONYM', 'PROCEDURE', 'FUNCTION')
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ' || obj.object_type || ' "' || obj.owner || '"."' || obj.object_name || '"';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

BEGIN
    FOR tbl IN (
        SELECT owner, table_name
        FROM all_tables
        WHERE table_name IN (
            'NOTIFICACION', 'CORTESIA_EVENTO', 'INVITADO_EVENTO', 'PAGO', 'PROYECTO_COMPLEMENTO', 'PROYECTO_EVENTO',
            'SOLICITUD_SERVICIO', 'PAQUETE_PLATILLO', 'PAQUETE_COMPLEMENTO', 'PAQUETE', 'SALON',
            'COMPLEMENTO', 'INSTRUCCION', 'PLATILLO_INGREDIENTE', 'INGREDIENTE',
            'PLATILLO', 'GERENTE', 'CLIENTE', 'USUARIO'
        )
        AND owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
        ORDER BY table_name
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "' || tbl.owner || '"."' || tbl.table_name || '" CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

BEGIN
    FOR seq IN (
        SELECT sequence_owner, sequence_name
        FROM all_sequences
        WHERE sequence_owner = SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE "' || seq.sequence_owner || '"."' || seq.sequence_name || '"';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/



-- ============================================================================
-- 01 DDL - TABLAS Y RESTRICCIONES
-- Archivo fuente: database\02_schema.sql
-- ============================================================================

-- Esquema principal para Banquetes Catherine.
-- Ejecutar conectado como BANQUETES_CATHERINE.

CREATE TABLE USUARIO (
    id_usuario NUMBER PRIMARY KEY,
    nombre_usuario VARCHAR2(50) NOT NULL,
    hash_contrasena VARCHAR2(255) NOT NULL,
    rol VARCHAR2(20) NOT NULL,
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    fecha_creacion DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_usuario_nombre UNIQUE (nombre_usuario),
    CONSTRAINT ck_usuario_rol CHECK (rol IN ('CLIENTE', 'GERENTE', 'GERENTE_ADMIN', 'CHEF')),
    CONSTRAINT ck_usuario_activo CHECK (activo IN ('S', 'N'))
);

CREATE TABLE CLIENTE (
    id_cliente NUMBER PRIMARY KEY,
    id_usuario NUMBER NOT NULL,
    nombre VARCHAR2(80) NOT NULL,
    apellido VARCHAR2(80) NOT NULL,
    correo VARCHAR2(120) NOT NULL,
    telefono VARCHAR2(30),
    direccion VARCHAR2(250),
    fecha_registro DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_cliente_usuario UNIQUE (id_usuario),
    CONSTRAINT uq_cliente_correo UNIQUE (correo),
    CONSTRAINT fk_cliente_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario)
);

CREATE TABLE GERENTE (
    id_gerente NUMBER PRIMARY KEY,
    id_usuario NUMBER NOT NULL,
    nombre VARCHAR2(120) NOT NULL,
    correo VARCHAR2(120) NOT NULL,
    telefono VARCHAR2(30),
    estatus VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    CONSTRAINT uq_gerente_usuario UNIQUE (id_usuario),
    CONSTRAINT uq_gerente_correo UNIQUE (correo),
    CONSTRAINT fk_gerente_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(id_usuario),
    CONSTRAINT ck_gerente_estatus CHECK (estatus IN ('ACTIVO', 'VACACIONES', 'INACTIVO', 'BAJA'))
);

CREATE TABLE PLATILLO (
    id_platillo NUMBER PRIMARY KEY,
    nombre VARCHAR2(120) NOT NULL,
    descripcion VARCHAR2(500),
    precio NUMBER(10,2) NOT NULL,
    costo_estimado NUMBER(10,2) DEFAULT 0 NOT NULL,
    -- El proyecto maneja recetas unitarias: las cantidades son por 1 persona.
    porciones_base NUMBER DEFAULT 1 NOT NULL,
    categoria VARCHAR2(60),
    tipo_dieta VARCHAR2(60),
    dificultad VARCHAR2(20) DEFAULT 'MEDIA' NOT NULL,
    foto_url VARCHAR2(250) DEFAULT 'img/hero-banquetes.png' NOT NULL,
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT uq_platillo_nombre UNIQUE (nombre),
    CONSTRAINT ck_platillo_precio CHECK (precio >= 0),
    CONSTRAINT ck_platillo_costo CHECK (costo_estimado >= 0),
    CONSTRAINT ck_platillo_porciones CHECK (porciones_base > 0),
    CONSTRAINT ck_platillo_dificultad CHECK (dificultad IN ('BAJA', 'MEDIA', 'ALTA')),
    CONSTRAINT ck_platillo_activo CHECK (activo IN ('S', 'N'))
);

CREATE TABLE INGREDIENTE (
    id_ingrediente NUMBER PRIMARY KEY,
    nombre_ingrediente VARCHAR2(120) NOT NULL,
    unidad_medida VARCHAR2(50) NOT NULL,
    presentacion VARCHAR2(150),
    observacion VARCHAR2(250),
    CONSTRAINT uq_ingrediente_nombre UNIQUE (nombre_ingrediente)
);

CREATE TABLE PLATILLO_INGREDIENTE (
    folio_pi NUMBER PRIMARY KEY,
    id_platillo NUMBER NOT NULL,
    id_ingrediente NUMBER NOT NULL,
    cantidad NUMBER(12,3) NOT NULL,
    CONSTRAINT fk_pi_platillo FOREIGN KEY (id_platillo) REFERENCES PLATILLO(id_platillo),
    CONSTRAINT fk_pi_ingrediente FOREIGN KEY (id_ingrediente) REFERENCES INGREDIENTE(id_ingrediente),
    CONSTRAINT uq_pi_platillo_ingrediente UNIQUE (id_platillo, id_ingrediente),
    CONSTRAINT ck_pi_cantidad CHECK (cantidad > 0)
);

CREATE TABLE INSTRUCCION (
    id_instruccion NUMBER PRIMARY KEY,
    id_platillo NUMBER NOT NULL,
    numero_paso NUMBER NOT NULL,
    instruccion VARCHAR2(500) NOT NULL,
    detalle_instruccion VARCHAR2(500),
    CONSTRAINT fk_inst_platillo FOREIGN KEY (id_platillo) REFERENCES PLATILLO(id_platillo),
    CONSTRAINT uq_inst_paso UNIQUE (id_platillo, numero_paso),
    CONSTRAINT ck_inst_paso CHECK (numero_paso > 0)
);

CREATE TABLE COMPLEMENTO (
    id_complemento NUMBER PRIMARY KEY,
    nombre VARCHAR2(120) NOT NULL,
    descripcion VARCHAR2(500),
    precio NUMBER(10,2) NOT NULL,
    tipo_complemento VARCHAR2(40) DEFAULT 'GENERAL' NOT NULL,
    tipo_cobro VARCHAR2(20) DEFAULT 'POR_EVENTO' NOT NULL,
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT uq_complemento_nombre UNIQUE (nombre),
    CONSTRAINT ck_complemento_precio CHECK (precio >= 0),
    CONSTRAINT ck_complemento_cobro CHECK (tipo_cobro IN ('POR_PERSONA', 'POR_EVENTO')),
    CONSTRAINT ck_complemento_activo CHECK (activo IN ('S', 'N'))
);

CREATE TABLE SALON (
    id_salon NUMBER PRIMARY KEY,
    nombre VARCHAR2(150) NOT NULL,
    direccion VARCHAR2(250) NOT NULL,
    zona VARCHAR2(120),
    descripcion VARCHAR2(700),
    foto_url VARCHAR2(250),
    convenio_activo CHAR(1) DEFAULT 'S' NOT NULL,
    costo_renta NUMBER(10,2) NOT NULL,
    capacidad_maxima NUMBER NOT NULL,
    contacto_instalacion VARCHAR2(120) NOT NULL,
    telefono_contacto VARCHAR2(30),
    correo_contacto VARCHAR2(120),
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT uq_salon_nombre UNIQUE (nombre),
    CONSTRAINT ck_salon_convenio CHECK (convenio_activo IN ('S', 'N')),
    CONSTRAINT ck_salon_costo CHECK (costo_renta >= 0),
    CONSTRAINT ck_salon_capacidad CHECK (capacidad_maxima > 0),
    CONSTRAINT ck_salon_activo CHECK (activo IN ('S', 'N'))
);

CREATE TABLE PAQUETE (
    id_paquete NUMBER PRIMARY KEY,
    nombre VARCHAR2(150) NOT NULL,
    descripcion VARCHAR2(500),
    precio_base NUMBER(10,2) NOT NULL,
    tipo_paquete VARCHAR2(40) DEFAULT 'SOCIAL' NOT NULL,
    margen_ganancia NUMBER(5,2) DEFAULT 30 NOT NULL,
    visible_publico CHAR(1) DEFAULT 'S' NOT NULL,
    personalizado CHAR(1) DEFAULT 'N' NOT NULL,
    id_cliente NUMBER,
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT fk_paquete_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    CONSTRAINT uq_paquete_nombre_cliente UNIQUE (nombre, id_cliente),
    CONSTRAINT ck_paquete_precio CHECK (precio_base >= 0),
    CONSTRAINT ck_paquete_margen CHECK (margen_ganancia >= 0),
    CONSTRAINT ck_paquete_visible CHECK (visible_publico IN ('S', 'N')),
    CONSTRAINT ck_paquete_personalizado CHECK (personalizado IN ('S', 'N')),
    CONSTRAINT ck_paquete_activo CHECK (activo IN ('S', 'N')),
    CONSTRAINT ck_paquete_privado CHECK (
        personalizado = 'N'
        OR (personalizado = 'S' AND visible_publico = 'N' AND id_cliente IS NOT NULL)
    )
);

CREATE TABLE PAQUETE_COMPLEMENTO (
    id_paquete_complemento NUMBER PRIMARY KEY,
    id_paquete NUMBER NOT NULL,
    id_complemento NUMBER NOT NULL,
    cantidad NUMBER DEFAULT 1 NOT NULL,
    CONSTRAINT fk_pcomp_paquete FOREIGN KEY (id_paquete) REFERENCES PAQUETE(id_paquete),
    CONSTRAINT fk_pcomp_complemento FOREIGN KEY (id_complemento) REFERENCES COMPLEMENTO(id_complemento),
    CONSTRAINT uq_pcomp_paquete_complemento UNIQUE (id_paquete, id_complemento),
    CONSTRAINT ck_pcomp_cantidad CHECK (cantidad > 0)
);

CREATE TABLE PAQUETE_PLATILLO (
    id_paquete_platillo NUMBER PRIMARY KEY,
    id_paquete NUMBER NOT NULL,
    id_platillo NUMBER NOT NULL,
    cantidad NUMBER DEFAULT 1 NOT NULL,
    CONSTRAINT fk_pp_paquete FOREIGN KEY (id_paquete) REFERENCES PAQUETE(id_paquete),
    CONSTRAINT fk_pp_platillo FOREIGN KEY (id_platillo) REFERENCES PLATILLO(id_platillo),
    CONSTRAINT uq_pp_paquete_platillo UNIQUE (id_paquete, id_platillo),
    CONSTRAINT ck_pp_cantidad CHECK (cantidad > 0)
);

CREATE TABLE SOLICITUD_SERVICIO (
    id_solicitud NUMBER PRIMARY KEY,
    nombre_contacto VARCHAR2(160) NOT NULL,
    correo VARCHAR2(120) NOT NULL,
    telefono VARCHAR2(30),
    fecha_evento DATE NOT NULL,
    numero_invitados NUMBER NOT NULL,
    id_salon_preferido NUMBER,
    id_paquete_preferido NUMBER,
    mensaje VARCHAR2(1000),
    estatus VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL,
    fecha_solicitud DATE DEFAULT SYSDATE NOT NULL,
    id_gerente_asignado NUMBER,
    observaciones VARCHAR2(1000),
    CONSTRAINT fk_sol_salon FOREIGN KEY (id_salon_preferido) REFERENCES SALON(id_salon),
    CONSTRAINT fk_sol_paquete FOREIGN KEY (id_paquete_preferido) REFERENCES PAQUETE(id_paquete),
    CONSTRAINT fk_sol_gerente FOREIGN KEY (id_gerente_asignado) REFERENCES GERENTE(id_gerente),
    CONSTRAINT ck_sol_invitados CHECK (numero_invitados > 0),
    CONSTRAINT ck_sol_estatus CHECK (estatus IN ('PENDIENTE', 'ATENDIDA', 'RECHAZADA', 'CONVERTIDA'))
);

CREATE TABLE PROYECTO_EVENTO (
    id_proyecto NUMBER PRIMARY KEY,
    id_solicitud NUMBER,
    id_cliente NUMBER NOT NULL,
    id_gerente NUMBER NOT NULL,
    id_salon NUMBER NOT NULL,
    id_paquete NUMBER NOT NULL,
    nombre_evento VARCHAR2(180) NOT NULL,
    fecha_evento DATE NOT NULL,
    numero_invitados NUMBER NOT NULL,
    total_estimado NUMBER(12,2) NOT NULL,
    finiquitado CHAR(1) DEFAULT 'N' NOT NULL,
    estatus VARCHAR2(20) DEFAULT 'ACTIVO' NOT NULL,
    codigo_acceso_hash VARCHAR2(255),
    fecha_creacion DATE DEFAULT SYSDATE NOT NULL,
    fecha_actualizacion DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_proyecto_solicitud UNIQUE (id_solicitud),
    CONSTRAINT fk_proy_solicitud FOREIGN KEY (id_solicitud) REFERENCES SOLICITUD_SERVICIO(id_solicitud),
    CONSTRAINT fk_proy_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    CONSTRAINT fk_proy_gerente FOREIGN KEY (id_gerente) REFERENCES GERENTE(id_gerente),
    CONSTRAINT fk_proy_salon FOREIGN KEY (id_salon) REFERENCES SALON(id_salon),
    CONSTRAINT fk_proy_paquete FOREIGN KEY (id_paquete) REFERENCES PAQUETE(id_paquete),
    CONSTRAINT ck_proy_invitados CHECK (numero_invitados > 0),
    CONSTRAINT ck_proy_total CHECK (total_estimado >= 0),
    CONSTRAINT ck_proy_finiquitado CHECK (finiquitado IN ('S', 'N')),
    CONSTRAINT ck_proy_estatus CHECK (estatus IN ('ACTIVO', 'REALIZADO', 'CANCELADO', 'RECHAZADO'))
);

CREATE TABLE PROYECTO_COMPLEMENTO (
    id_proyecto_complemento NUMBER PRIMARY KEY,
    id_proyecto NUMBER NOT NULL,
    id_complemento NUMBER NOT NULL,
    cantidad NUMBER DEFAULT 1 NOT NULL,
    precio_unitario NUMBER(10,2) NOT NULL,
    CONSTRAINT fk_pc_proyecto FOREIGN KEY (id_proyecto) REFERENCES PROYECTO_EVENTO(id_proyecto),
    CONSTRAINT fk_pc_complemento FOREIGN KEY (id_complemento) REFERENCES COMPLEMENTO(id_complemento),
    CONSTRAINT uq_pc_proyecto_complemento UNIQUE (id_proyecto, id_complemento),
    CONSTRAINT ck_pc_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_pc_precio CHECK (precio_unitario >= 0)
);

CREATE TABLE PAGO (
    id_pago NUMBER PRIMARY KEY,
    id_proyecto NUMBER NOT NULL,
    monto NUMBER(12,2) NOT NULL,
    tipo_pago VARCHAR2(20) NOT NULL,
    metodo_pago VARCHAR2(40) NOT NULL,
    fecha_pago DATE DEFAULT SYSDATE NOT NULL,
    referencia VARCHAR2(120),
    CONSTRAINT fk_pago_proyecto FOREIGN KEY (id_proyecto) REFERENCES PROYECTO_EVENTO(id_proyecto),
    CONSTRAINT ck_pago_monto CHECK (monto > 0),
    CONSTRAINT ck_pago_tipo CHECK (tipo_pago IN ('ANTICIPO', 'ABONO', 'LIQUIDACION', 'AJUSTE')),
    CONSTRAINT uq_pago_referencia UNIQUE (referencia)
);

CREATE TABLE INVITADO_EVENTO (
    id_invitado NUMBER PRIMARY KEY,
    id_proyecto NUMBER NOT NULL,
    nombre VARCHAR2(160) NOT NULL,
    correo VARCHAR2(120),
    telefono VARCHAR2(30),
    estatus_confirmacion VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL,
    fecha_invitacion DATE DEFAULT SYSDATE NOT NULL,
    fecha_respuesta DATE,
    CONSTRAINT fk_inv_proyecto FOREIGN KEY (id_proyecto) REFERENCES PROYECTO_EVENTO(id_proyecto),
    CONSTRAINT uq_inv_correo_proyecto UNIQUE (id_proyecto, correo),
    CONSTRAINT ck_inv_estatus CHECK (estatus_confirmacion IN ('PENDIENTE', 'CONFIRMADO', 'RECHAZADO'))
);

CREATE TABLE CORTESIA_EVENTO (
    id_cortesia NUMBER PRIMARY KEY,
    id_proyecto NUMBER NOT NULL,
    tipo_cortesia VARCHAR2(30) NOT NULL,
    titulo VARCHAR2(160) NOT NULL,
    detalle VARCHAR2(800),
    estatus VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL,
    fecha_registro DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_cortesia_proyecto FOREIGN KEY (id_proyecto) REFERENCES PROYECTO_EVENTO(id_proyecto),
    CONSTRAINT ck_cortesia_tipo CHECK (tipo_cortesia IN ('AGENDA', 'PENDIENTE', 'MONTAJE', 'MUSICA', 'DIETA')),
    CONSTRAINT ck_cortesia_estatus CHECK (estatus IN ('PENDIENTE', 'LISTO'))
);

CREATE TABLE NOTIFICACION (
    id_notificacion NUMBER PRIMARY KEY,
    tipo_destinatario VARCHAR2(30) NOT NULL,
    id_destinatario NUMBER,
    id_proyecto NUMBER,
    id_salon NUMBER,
    canal VARCHAR2(30) DEFAULT 'WEB' NOT NULL,
    asunto VARCHAR2(180) NOT NULL,
    mensaje VARCHAR2(1000) NOT NULL,
    estatus VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL,
    fecha_creacion DATE DEFAULT SYSDATE NOT NULL,
    fecha_lectura DATE,
    CONSTRAINT fk_not_proyecto FOREIGN KEY (id_proyecto) REFERENCES PROYECTO_EVENTO(id_proyecto),
    CONSTRAINT fk_not_salon FOREIGN KEY (id_salon) REFERENCES SALON(id_salon),
    CONSTRAINT ck_not_destino CHECK (tipo_destinatario IN ('CLIENTE', 'GERENTE', 'INSTALACION', 'COBRANZA', 'SISTEMA')),
    CONSTRAINT ck_not_estatus CHECK (estatus IN ('PENDIENTE', 'LEIDA', 'ENVIADA')),
    CONSTRAINT ck_not_canal CHECK (canal IN ('WEB', 'CORREO', 'TELEFONO'))
);

-- Evidencia ALTER TABLE del temario: se agrega una columna no critica despues del CREATE.
ALTER TABLE SOLICITUD_SERVICIO ADD origen VARCHAR2(40) DEFAULT 'WEB' NOT NULL;



-- ============================================================================
-- 02 SECUENCIAS E INDICES
-- Archivo fuente: database\03_secuencias_indices.sql
-- ============================================================================

-- Secuencias Oracle para claves primarias.

CREATE SEQUENCE sq_usuario START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_cliente START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_gerente START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_platillo START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_ingrediente START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_platillo_ingrediente START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_instruccion START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_complemento START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_salon START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_paquete START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_paquete_complemento START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_paquete_platillo START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_solicitud START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_proyecto START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_proyecto_complemento START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_pago START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_invitado START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_cortesia START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE sq_notificacion START WITH 1 INCREMENT BY 1 NOCACHE;

-- Indices para busquedas, joins y reportes.

CREATE INDEX ix_usuario_rol ON USUARIO(rol, activo);
CREATE INDEX ix_cliente_nombre ON CLIENTE(nombre, apellido);
CREATE INDEX ix_gerente_estatus ON GERENTE(estatus);
CREATE INDEX ix_platillo_categoria ON PLATILLO(categoria, activo);
CREATE INDEX ix_salon_capacidad ON SALON(capacidad_maxima, convenio_activo, activo);
CREATE INDEX ix_solicitud_estatus_fecha ON SOLICITUD_SERVICIO(estatus, fecha_evento);
CREATE INDEX ix_proyecto_fecha_estatus ON PROYECTO_EVENTO(fecha_evento, estatus);
CREATE INDEX ix_proyecto_cliente ON PROYECTO_EVENTO(id_cliente, estatus);
CREATE INDEX ix_proyecto_finiquitado ON PROYECTO_EVENTO(finiquitado, fecha_evento);
CREATE INDEX ix_pago_proyecto_fecha ON PAGO(id_proyecto, fecha_pago);
CREATE INDEX ix_invitado_proyecto_estatus ON INVITADO_EVENTO(id_proyecto, estatus_confirmacion);
CREATE INDEX ix_cortesia_proyecto_tipo ON CORTESIA_EVENTO(id_proyecto, tipo_cortesia, estatus);
CREATE INDEX ix_notificacion_destino ON NOTIFICACION(tipo_destinatario, id_destinatario, estatus);



-- ============================================================================
-- 03 VISTAS Y SINONIMOS
-- Archivo fuente: database\04_vistas_sinonimos.sql
-- ============================================================================

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



-- ============================================================================
-- 04 FUNCIONES Y PROCEDIMIENTOS PL SQL
-- Archivo fuente: database\05_funciones_procedimientos.sql
-- ============================================================================

-- Funciones PL/SQL que devuelven valores.

CREATE OR REPLACE FUNCTION fn_total_pagado(p_id_proyecto IN NUMBER)
RETURN NUMBER
IS
    v_total NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(monto), 0)
    INTO v_total
    FROM PAGO
    WHERE id_proyecto = p_id_proyecto;

    RETURN v_total;
END;
/

CREATE OR REPLACE FUNCTION fn_saldo_pendiente(p_id_proyecto IN NUMBER)
RETURN NUMBER
IS
    v_total_estimado PROYECTO_EVENTO.total_estimado%TYPE;
BEGIN
    SELECT total_estimado
    INTO v_total_estimado
    FROM PROYECTO_EVENTO
    WHERE id_proyecto = p_id_proyecto;

    RETURN GREATEST(v_total_estimado - fn_total_pagado(p_id_proyecto), 0);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

CREATE OR REPLACE FUNCTION fn_dias_para_evento(p_id_proyecto IN NUMBER)
RETURN NUMBER
IS
    v_dias NUMBER;
BEGIN
    SELECT TRUNC(fecha_evento) - TRUNC(SYSDATE)
    INTO v_dias
    FROM PROYECTO_EVENTO
    WHERE id_proyecto = p_id_proyecto;

    RETURN v_dias;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

CREATE OR REPLACE FUNCTION fn_salones_sugeridos(p_invitados IN NUMBER)
RETURN VARCHAR2
IS
    v_salones VARCHAR2(1000);
BEGIN
    SELECT LISTAGG(nombre || ' (' || capacidad_maxima || ' personas)', ', ')
           WITHIN GROUP (ORDER BY capacidad_maxima)
    INTO v_salones
    FROM SALON
    WHERE activo = 'S'
      AND convenio_activo = 'S'
      AND capacidad_maxima >= p_invitados;

    RETURN NVL(v_salones, 'No hay salones disponibles con esa capacidad');
END;
/

CREATE OR REPLACE FUNCTION fn_numero_ingredientes_platillo(p_id_platillo IN NUMBER)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(1)
    INTO v_total
    FROM PLATILLO_INGREDIENTE
    WHERE id_platillo = p_id_platillo;

    RETURN v_total;
END;
/

CREATE OR REPLACE FUNCTION fn_complementos_evento_paquete(p_id_paquete IN NUMBER)
RETURN NUMBER
IS
    v_total NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(c.precio * pc.cantidad), 0)
    INTO v_total
    FROM PAQUETE_COMPLEMENTO pc
    INNER JOIN COMPLEMENTO c ON c.id_complemento = pc.id_complemento
    WHERE pc.id_paquete = p_id_paquete
      AND c.tipo_cobro = 'POR_EVENTO'
      AND c.activo = 'S';

    RETURN v_total;
END;
/

CREATE OR REPLACE FUNCTION fn_costo_paquete_persona(p_id_paquete IN NUMBER)
RETURN NUMBER
IS
    v_precio PAQUETE.precio_base%TYPE;
    v_complementos_persona NUMBER(12,2);
BEGIN
    SELECT precio_base
    INTO v_precio
    FROM PAQUETE
    WHERE id_paquete = p_id_paquete
      AND activo = 'S';

    SELECT NVL(SUM(c.precio * pc.cantidad), 0)
    INTO v_complementos_persona
    FROM PAQUETE_COMPLEMENTO pc
    INNER JOIN COMPLEMENTO c ON c.id_complemento = pc.id_complemento
    WHERE pc.id_paquete = p_id_paquete
      AND c.tipo_cobro = 'POR_PERSONA'
      AND c.activo = 'S';

    RETURN v_precio + v_complementos_persona;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

CREATE OR REPLACE FUNCTION fn_total_estimado_evento(
    p_numero_invitados IN NUMBER,
    p_id_salon IN NUMBER,
    p_id_paquete IN NUMBER
)
RETURN NUMBER
IS
    v_costo_persona NUMBER(12,2);
    v_renta_salon SALON.costo_renta%TYPE;
    v_complementos_evento NUMBER(12,2);
BEGIN
    SELECT costo_renta
    INTO v_renta_salon
    FROM SALON
    WHERE id_salon = p_id_salon
      AND activo = 'S'
      AND convenio_activo = 'S';

    v_costo_persona := fn_costo_paquete_persona(p_id_paquete);
    v_complementos_evento := fn_complementos_evento_paquete(p_id_paquete);

    RETURN ROUND((NVL(v_costo_persona, 0) * p_numero_invitados) + v_renta_salon + v_complementos_evento, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END;
/

-- Procedimientos PL/SQL con DML y control de transacciones.

CREATE OR REPLACE PROCEDURE sp_insertar_notificacion(
    p_tipo_destinatario IN VARCHAR2,
    p_id_destinatario IN NUMBER,
    p_id_proyecto IN NUMBER,
    p_id_salon IN NUMBER,
    p_canal IN VARCHAR2,
    p_asunto IN VARCHAR2,
    p_mensaje IN VARCHAR2
)
IS
BEGIN
    INSERT INTO NOTIFICACION (
        id_notificacion,
        tipo_destinatario,
        id_destinatario,
        id_proyecto,
        id_salon,
        canal,
        asunto,
        mensaje
    ) VALUES (
        sq_notificacion.NEXTVAL,
        p_tipo_destinatario,
        p_id_destinatario,
        p_id_proyecto,
        p_id_salon,
        NVL(p_canal, 'WEB'),
        p_asunto,
        p_mensaje
    );
END;
/

CREATE OR REPLACE PROCEDURE sp_crear_solicitud(
    p_nombre_contacto IN VARCHAR2,
    p_correo IN VARCHAR2,
    p_telefono IN VARCHAR2,
    p_fecha_evento IN DATE,
    p_numero_invitados IN NUMBER,
    p_id_salon_preferido IN NUMBER,
    p_id_paquete_preferido IN NUMBER,
    p_mensaje IN VARCHAR2,
    p_id_solicitud OUT NUMBER
)
IS
BEGIN
    INSERT INTO SOLICITUD_SERVICIO (
        id_solicitud,
        nombre_contacto,
        correo,
        telefono,
        fecha_evento,
        numero_invitados,
        id_salon_preferido,
        id_paquete_preferido,
        mensaje
    ) VALUES (
        sq_solicitud.NEXTVAL,
        INITCAP(TRIM(p_nombre_contacto)),
        LOWER(TRIM(p_correo)),
        p_telefono,
        p_fecha_evento,
        p_numero_invitados,
        p_id_salon_preferido,
        p_id_paquete_preferido,
        p_mensaje
    )
    RETURNING id_solicitud INTO p_id_solicitud;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_crear_proyecto_desde_solicitud(
    p_id_solicitud IN NUMBER,
    p_id_cliente IN NUMBER,
    p_id_gerente IN NUMBER,
    p_id_salon IN NUMBER,
    p_id_paquete IN NUMBER,
    p_nombre_evento IN VARCHAR2,
    p_total_estimado IN NUMBER,
    p_anticipo IN NUMBER,
    p_metodo_pago IN VARCHAR2,
    p_referencia IN VARCHAR2,
    p_id_proyecto OUT NUMBER
)
IS
    v_fecha_evento SOLICITUD_SERVICIO.fecha_evento%TYPE;
    v_invitados SOLICITUD_SERVICIO.numero_invitados%TYPE;
    v_estatus_solicitud SOLICITUD_SERVICIO.estatus%TYPE;
    v_capacidad SALON.capacidad_maxima%TYPE;
    v_convenio SALON.convenio_activo%TYPE;
    v_activo_salon SALON.activo%TYPE;
    v_estatus_gerente GERENTE.estatus%TYPE;
    v_personalizado PAQUETE.personalizado%TYPE;
    v_cliente_paquete PAQUETE.id_cliente%TYPE;
    v_sugerencias VARCHAR2(1000);
    v_total_estimado PROYECTO_EVENTO.total_estimado%TYPE;
BEGIN
    SAVEPOINT antes_de_crear_proyecto;

    SELECT fecha_evento, numero_invitados, estatus
    INTO v_fecha_evento, v_invitados, v_estatus_solicitud
    FROM SOLICITUD_SERVICIO
    WHERE id_solicitud = p_id_solicitud
    FOR UPDATE;

    IF v_estatus_solicitud <> 'PENDIENTE' THEN
        RAISE_APPLICATION_ERROR(-20001, 'La solicitud ya fue atendida o convertida.');
    END IF;

    SELECT estatus
    INTO v_estatus_gerente
    FROM GERENTE
    WHERE id_gerente = p_id_gerente;

    IF v_estatus_gerente <> 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20002, 'El gerente no esta activo.');
    END IF;

    SELECT capacidad_maxima, convenio_activo, activo
    INTO v_capacidad, v_convenio, v_activo_salon
    FROM SALON
    WHERE id_salon = p_id_salon;

    IF v_activo_salon <> 'S' OR v_convenio <> 'S' THEN
        RAISE_APPLICATION_ERROR(-20003, 'El salon no tiene convenio activo.');
    END IF;

    IF v_capacidad < v_invitados THEN
        v_sugerencias := fn_salones_sugeridos(v_invitados);
        RAISE_APPLICATION_ERROR(-20004, 'El salon no tiene capacidad suficiente. Alternativas: ' || v_sugerencias);
    END IF;

    SELECT personalizado, id_cliente
    INTO v_personalizado, v_cliente_paquete
    FROM PAQUETE
    WHERE id_paquete = p_id_paquete
      AND activo = 'S';

    IF v_personalizado = 'S' AND NVL(v_cliente_paquete, -1) <> p_id_cliente THEN
        RAISE_APPLICATION_ERROR(-20005, 'El paquete personalizado no pertenece al cliente.');
    END IF;

    IF p_anticipo <= 0 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Debe registrarse un anticipo mayor a cero.');
    END IF;

    IF p_total_estimado IS NULL OR p_total_estimado <= 0 THEN
        v_total_estimado := fn_total_estimado_evento(v_invitados, p_id_salon, p_id_paquete);
    ELSE
        v_total_estimado := p_total_estimado;
    END IF;

    INSERT INTO PROYECTO_EVENTO (
        id_proyecto,
        id_solicitud,
        id_cliente,
        id_gerente,
        id_salon,
        id_paquete,
        nombre_evento,
        fecha_evento,
        numero_invitados,
        total_estimado,
        finiquitado,
        codigo_acceso_hash
    ) VALUES (
        sq_proyecto.NEXTVAL,
        p_id_solicitud,
        p_id_cliente,
        p_id_gerente,
        p_id_salon,
        p_id_paquete,
        INITCAP(TRIM(p_nombre_evento)),
        v_fecha_evento,
        v_invitados,
        v_total_estimado,
        CASE WHEN p_anticipo >= v_total_estimado THEN 'S' ELSE 'N' END,
        STANDARD_HASH(TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF') || p_id_cliente || p_id_solicitud, 'SHA256')
    )
    RETURNING id_proyecto INTO p_id_proyecto;

    INSERT INTO PAGO (
        id_pago,
        id_proyecto,
        monto,
        tipo_pago,
        metodo_pago,
        referencia
    ) VALUES (
        sq_pago.NEXTVAL,
        p_id_proyecto,
        p_anticipo,
        'ANTICIPO',
        p_metodo_pago,
        p_referencia
    );

    UPDATE SOLICITUD_SERVICIO
    SET estatus = 'CONVERTIDA',
        id_gerente_asignado = p_id_gerente,
        observaciones = 'Convertida a proyecto ' || p_id_proyecto
    WHERE id_solicitud = p_id_solicitud;

    sp_insertar_notificacion('CLIENTE', p_id_cliente, p_id_proyecto, NULL, 'WEB',
        'Proyecto creado', 'Su evento fue confirmado y se registro el anticipo.');
    sp_insertar_notificacion('GERENTE', p_id_gerente, p_id_proyecto, NULL, 'WEB',
        'Nuevo proyecto asignado', 'Se creo un proyecto desde la solicitud ' || p_id_solicitud || '.');
    sp_insertar_notificacion('INSTALACION', NULL, p_id_proyecto, p_id_salon, 'CORREO',
        'Evento confirmado', 'Se confirmo un evento para ' || v_invitados || ' invitados.');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO antes_de_crear_proyecto;
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_registrar_pago(
    p_id_proyecto IN NUMBER,
    p_monto IN NUMBER,
    p_tipo_pago IN VARCHAR2,
    p_metodo_pago IN VARCHAR2,
    p_referencia IN VARCHAR2
)
IS
    v_total PROYECTO_EVENTO.total_estimado%TYPE;
    v_pagado NUMBER(12,2);
    v_id_cliente PROYECTO_EVENTO.id_cliente%TYPE;
BEGIN
    SAVEPOINT antes_de_pago;

    SELECT total_estimado, id_cliente
    INTO v_total, v_id_cliente
    FROM PROYECTO_EVENTO
    WHERE id_proyecto = p_id_proyecto
    FOR UPDATE;

    INSERT INTO PAGO (
        id_pago,
        id_proyecto,
        monto,
        tipo_pago,
        metodo_pago,
        referencia
    ) VALUES (
        sq_pago.NEXTVAL,
        p_id_proyecto,
        p_monto,
        p_tipo_pago,
        p_metodo_pago,
        p_referencia
    );

    v_pagado := fn_total_pagado(p_id_proyecto);

    IF v_pagado >= v_total THEN
        UPDATE PROYECTO_EVENTO
        SET finiquitado = 'S',
            fecha_actualizacion = SYSDATE
        WHERE id_proyecto = p_id_proyecto;

        sp_insertar_notificacion('CLIENTE', v_id_cliente, p_id_proyecto, NULL, 'WEB',
            'Evento finiquitado', 'Los pagos cubren el total estimado del evento.');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO antes_de_pago;
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_actualizar_invitados(
    p_id_usuario_cliente IN NUMBER,
    p_id_proyecto IN NUMBER,
    p_numero_invitados IN NUMBER
)
IS
    v_id_cliente CLIENTE.id_cliente%TYPE;
    v_fecha_evento PROYECTO_EVENTO.fecha_evento%TYPE;
    v_id_salon PROYECTO_EVENTO.id_salon%TYPE;
    v_id_paquete PROYECTO_EVENTO.id_paquete%TYPE;
    v_capacidad SALON.capacidad_maxima%TYPE;
    v_invitados_anteriores PROYECTO_EVENTO.numero_invitados%TYPE;
    v_total_estimado PROYECTO_EVENTO.total_estimado%TYPE;
BEGIN
    SAVEPOINT antes_de_cambio_invitados;

    SELECT c.id_cliente, pe.fecha_evento, pe.id_salon, pe.id_paquete, pe.numero_invitados
    INTO v_id_cliente, v_fecha_evento, v_id_salon, v_id_paquete, v_invitados_anteriores
    FROM PROYECTO_EVENTO pe
    INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
    WHERE pe.id_proyecto = p_id_proyecto
      AND c.id_usuario = p_id_usuario_cliente
      AND pe.estatus = 'ACTIVO'
    FOR UPDATE;

    IF TRUNC(v_fecha_evento) - TRUNC(SYSDATE) < 5 THEN
        RAISE_APPLICATION_ERROR(-20010, 'No se puede cambiar invitados cuando faltan menos de 5 dias.');
    END IF;

    SELECT capacidad_maxima
    INTO v_capacidad
    FROM SALON
    WHERE id_salon = v_id_salon;

    IF p_numero_invitados > v_capacidad THEN
        RAISE_APPLICATION_ERROR(-20011, 'El salon no tiene capacidad. Alternativas: ' || fn_salones_sugeridos(p_numero_invitados));
    END IF;

    v_total_estimado := fn_total_estimado_evento(p_numero_invitados, v_id_salon, v_id_paquete);

    UPDATE PROYECTO_EVENTO
    SET numero_invitados = p_numero_invitados,
        total_estimado = v_total_estimado,
        finiquitado = CASE WHEN fn_total_pagado(p_id_proyecto) >= v_total_estimado THEN 'S' ELSE 'N' END,
        fecha_actualizacion = SYSDATE
    WHERE id_proyecto = p_id_proyecto;

    sp_insertar_notificacion('GERENTE', NULL, p_id_proyecto, NULL, 'WEB',
        'Cambio de invitados', 'El cliente cambio invitados de ' || v_invitados_anteriores || ' a ' || p_numero_invitados || '. Nuevo total: $' || TO_CHAR(v_total_estimado, '9999990.00') || '.');
    sp_insertar_notificacion('INSTALACION', NULL, p_id_proyecto, v_id_salon, 'CORREO',
        'Cambio relevante para instalacion', 'Actualizar montaje para ' || p_numero_invitados || ' invitados.');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO antes_de_cambio_invitados;
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_cancelar_evento(
    p_id_usuario_gerente IN NUMBER,
    p_id_proyecto IN NUMBER,
    p_motivo IN VARCHAR2
)
IS
    v_id_gerente GERENTE.id_gerente%TYPE;
    v_id_salon PROYECTO_EVENTO.id_salon%TYPE;
BEGIN
    SAVEPOINT antes_de_cancelar_evento;

    SELECT g.id_gerente
    INTO v_id_gerente
    FROM GERENTE g
    INNER JOIN USUARIO u ON u.id_usuario = g.id_usuario
    WHERE u.id_usuario = p_id_usuario_gerente
      AND u.rol IN ('GERENTE', 'GERENTE_ADMIN')
      AND g.estatus = 'ACTIVO';

    SELECT id_salon
    INTO v_id_salon
    FROM PROYECTO_EVENTO
    WHERE id_proyecto = p_id_proyecto
    FOR UPDATE;

    UPDATE PROYECTO_EVENTO
    SET estatus = 'CANCELADO',
        fecha_actualizacion = SYSDATE
    WHERE id_proyecto = p_id_proyecto;

    sp_insertar_notificacion('CLIENTE', NULL, p_id_proyecto, NULL, 'WEB',
        'Evento cancelado', 'El evento fue cancelado. Motivo: ' || p_motivo);
    sp_insertar_notificacion('INSTALACION', NULL, p_id_proyecto, v_id_salon, 'CORREO',
        'Cancelacion de evento', 'Cancelar preparativos del proyecto ' || p_id_proyecto || '.');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO antes_de_cancelar_evento;
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_cambiar_estatus_gerente(
    p_id_usuario_admin IN NUMBER,
    p_id_gerente IN NUMBER,
    p_estatus IN VARCHAR2
)
IS
    v_rol USUARIO.rol%TYPE;
BEGIN
    SELECT rol
    INTO v_rol
    FROM USUARIO
    WHERE id_usuario = p_id_usuario_admin
      AND activo = 'S';

    IF v_rol <> 'GERENTE_ADMIN' THEN
        RAISE_APPLICATION_ERROR(-20020, 'Solo GERENTE_ADMIN puede cambiar estatus de gerentes.');
    END IF;

    UPDATE GERENTE
    SET estatus = p_estatus
    WHERE id_gerente = p_id_gerente;

    sp_insertar_notificacion('GERENTE', p_id_gerente, NULL, NULL, 'WEB',
        'Estatus actualizado', 'El estatus del gerente cambio a ' || p_estatus || '.');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_crear_paquete_personalizado(
    p_id_cliente IN NUMBER,
    p_nombre IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_precio_base IN NUMBER,
    p_id_paquete OUT NUMBER
)
IS
BEGIN
    INSERT INTO PAQUETE (
        id_paquete,
        nombre,
        descripcion,
        precio_base,
        visible_publico,
        personalizado,
        id_cliente
    ) VALUES (
        sq_paquete.NEXTVAL,
        INITCAP(TRIM(p_nombre)),
        p_descripcion,
        p_precio_base,
        'N',
        'S',
        p_id_cliente
    )
    RETURNING id_paquete INTO p_id_paquete;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_agregar_platillo_paquete(
    p_id_paquete IN NUMBER,
    p_id_platillo IN NUMBER,
    p_cantidad IN NUMBER
)
IS
BEGIN
    INSERT INTO PAQUETE_PLATILLO (
        id_paquete_platillo,
        id_paquete,
        id_platillo,
        cantidad
    ) VALUES (
        sq_paquete_platillo.NEXTVAL,
        p_id_paquete,
        p_id_platillo,
        p_cantidad
    );

    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, 'El platillo ya existe en el paquete.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_alta_platillo(
    p_nombre IN VARCHAR2,
    p_descripcion IN VARCHAR2,
    p_precio IN NUMBER,
    p_costo_estimado IN NUMBER,
    p_porciones_base IN NUMBER,
    p_categoria IN VARCHAR2,
    p_tipo_dieta IN VARCHAR2,
    p_dificultad IN VARCHAR2,
    p_id_platillo OUT NUMBER
)
IS
BEGIN
    SAVEPOINT antes_de_platillo;

    INSERT INTO PLATILLO (
        id_platillo,
        nombre,
        descripcion,
        precio,
        costo_estimado,
        porciones_base,
        categoria,
        tipo_dieta,
        dificultad
    ) VALUES (
        sq_platillo.NEXTVAL,
        UPPER(TRIM(p_nombre)),
        p_descripcion,
        p_precio,
        p_costo_estimado,
        1,
        p_categoria,
        p_tipo_dieta,
        UPPER(TRIM(p_dificultad))
    )
    RETURNING id_platillo INTO p_id_platillo;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO antes_de_platillo;
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_registrar_invitado(
    p_id_usuario_cliente IN NUMBER,
    p_id_proyecto IN NUMBER,
    p_nombre IN VARCHAR2,
    p_correo IN VARCHAR2,
    p_telefono IN VARCHAR2,
    p_id_invitado OUT NUMBER
)
IS
    v_id_cliente CLIENTE.id_cliente%TYPE;
BEGIN
    SAVEPOINT antes_de_invitado;

    SELECT c.id_cliente
    INTO v_id_cliente
    FROM CLIENTE c
    INNER JOIN PROYECTO_EVENTO pe ON pe.id_cliente = c.id_cliente
    WHERE c.id_usuario = p_id_usuario_cliente
      AND pe.id_proyecto = p_id_proyecto
      AND pe.estatus = 'ACTIVO';

    INSERT INTO INVITADO_EVENTO (
        id_invitado,
        id_proyecto,
        nombre,
        correo,
        telefono
    ) VALUES (
        sq_invitado.NEXTVAL,
        p_id_proyecto,
        INITCAP(TRIM(p_nombre)),
        LOWER(TRIM(p_correo)),
        p_telefono
    )
    RETURNING id_invitado INTO p_id_invitado;

    sp_insertar_notificacion('CLIENTE', v_id_cliente, p_id_proyecto, NULL, 'WEB',
        'Invitado agregado', 'Se agrego a la lista de invitados: ' || INITCAP(TRIM(p_nombre)) || '.');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO antes_de_invitado;
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_confirmar_invitado(
    p_id_usuario_cliente IN NUMBER,
    p_id_invitado IN NUMBER,
    p_estatus_confirmacion IN VARCHAR2
)
IS
    v_id_cliente CLIENTE.id_cliente%TYPE;
    v_id_proyecto PROYECTO_EVENTO.id_proyecto%TYPE;
BEGIN
    SAVEPOINT antes_de_confirmacion;

    SELECT c.id_cliente, pe.id_proyecto
    INTO v_id_cliente, v_id_proyecto
    FROM INVITADO_EVENTO inv
    INNER JOIN PROYECTO_EVENTO pe ON pe.id_proyecto = inv.id_proyecto
    INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
    WHERE c.id_usuario = p_id_usuario_cliente
      AND inv.id_invitado = p_id_invitado
    FOR UPDATE;

    UPDATE INVITADO_EVENTO
    SET estatus_confirmacion = p_estatus_confirmacion,
        fecha_respuesta = SYSDATE
    WHERE id_invitado = p_id_invitado;

    sp_insertar_notificacion('CLIENTE', v_id_cliente, v_id_proyecto, NULL, 'WEB',
        'Confirmacion de invitado', 'Un invitado quedo con estatus ' || p_estatus_confirmacion || '.');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO antes_de_confirmacion;
        ROLLBACK;
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE sp_generar_notificaciones_cobranza
IS
BEGIN
    FOR evento IN (
        SELECT id_proyecto, cliente, dias_restantes, saldo_pendiente
        FROM vw_eventos_no_finiquitados_21
    ) LOOP
        INSERT INTO NOTIFICACION (
            id_notificacion,
            tipo_destinatario,
            id_proyecto,
            canal,
            asunto,
            mensaje
        )
        SELECT
            sq_notificacion.NEXTVAL,
            'COBRANZA',
            evento.id_proyecto,
            'WEB',
            'Evento no finiquitado',
            'El evento de ' || evento.cliente || ' esta a ' || evento.dias_restantes ||
            ' dias y tiene saldo pendiente de $' || TO_CHAR(evento.saldo_pendiente, '9999990.00')
        FROM dual
        WHERE NOT EXISTS (
            SELECT 1
            FROM NOTIFICACION n
            WHERE n.id_proyecto = evento.id_proyecto
              AND n.tipo_destinatario = 'COBRANZA'
              AND n.asunto = 'Evento no finiquitado'
        );
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/



-- ============================================================================
-- 05 DML - DATOS DE PRUEBA
-- Archivo fuente: database\06_datos_prueba.sql
-- ============================================================================

-- Datos de prueba para demo.
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

-- Usuarios: password demo en README.
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'admin.catherine', 'pbkdf2_sha256$260000$banquetes2026$jyuTR0uJhoRjlMBqLi7n0T57qiaHL+CAlouleZvQ6b0=', 'GERENTE_ADMIN', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'gerente.lucia', 'pbkdf2_sha256$260000$banquetes2026$kJvbx30T9M9Wh566lhW/mz4Wi8deYLS9OOS7+bRrKtk=', 'GERENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'gerente.mateo', 'pbkdf2_sha256$260000$banquetes2026$kJvbx30T9M9Wh566lhW/mz4Wi8deYLS9OOS7+bRrKtk=', 'GERENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.demo', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.sofia', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.diego', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.valeria', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.andres', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.maria', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.jorge', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.paola', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.ricardo', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.elena', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'chef.renata', 'pbkdf2_sha256$260000$banquetes2026$kJvbx30T9M9Wh566lhW/mz4Wi8deYLS9OOS7+bRrKtk=', 'CHEF', 'S', SYSDATE);

INSERT INTO GERENTE VALUES (sq_gerente.NEXTVAL, 1, 'Catherine Rivera', 'admin@banquetescatherine.local', '555-100-0001', 'ACTIVO');
INSERT INTO GERENTE VALUES (sq_gerente.NEXTVAL, 2, 'Lucia Montes', 'lucia@banquetescatherine.local', '555-100-0002', 'ACTIVO');
INSERT INTO GERENTE VALUES (sq_gerente.NEXTVAL, 3, 'Mateo Solis', 'mateo@banquetescatherine.local', '555-100-0003', 'VACACIONES');

INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 4, 'Ana', 'Lopez', 'ana.lopez@example.com', '555-200-0001', 'Av. Reforma 101', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 5, 'Sofia', 'Nava', 'sofia.nava@example.com', '555-200-0002', 'Calle Palma 22', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 6, 'Diego', 'Ramos', 'diego.ramos@example.com', '555-200-0003', 'Av. Rio 73', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 7, 'Valeria', 'Cruz', 'valeria.cruz@example.com', '555-200-0004', 'Calle Norte 9', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 8, 'Andres', 'Mora', 'andres.mora@example.com', '555-200-0005', 'Blvd. Central 15', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 9, 'Maria', 'Santos', 'maria.santos@example.com', '555-200-0006', 'Privada Olivo 4', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 10, 'Jorge', 'Paz', 'jorge.paz@example.com', '555-200-0007', 'Av. Sierra 211', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 11, 'Paola', 'Vega', 'paola.vega@example.com', '555-200-0008', 'Calle Luna 17', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 12, 'Ricardo', 'Leon', 'ricardo.leon@example.com', '555-200-0009', 'Calle Mar 88', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 13, 'Elena', 'Campos', 'elena.campos@example.com', '555-200-0010', 'Av. Jardin 42', SYSDATE);

INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'BROCHETA DE RES', 'Brochetas de res con vegetales asados', 185.00, 82.00, 4, 'FUERTE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'CHILES RELLENOS DE QUESO', 'Chiles poblanos rellenos con salsa de tomate', 145.00, 61.00, 4, 'FUERTE', 'VEGETARIANO', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'FILETE MIGNON CON CHAMPINONES', 'Filete de res con salsa de champinones', 260.00, 138.00, 6, 'FUERTE', 'PREMIUM', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'PESCADO AL VAPOR', 'Pescado blanco con verduras y salsa ligera', 175.00, 79.00, 4, 'FUERTE', 'LIGERO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'POLLO A LA CERVEZA', 'Pollo en salsa de cerveza y especias', 155.00, 65.00, 4, 'FUERTE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'CREMA DE ELOTE', 'Entrada cremosa con elote dulce', 75.00, 28.00, 8, 'ENTRADA', 'VEGETARIANO', 'BAJA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'ENSALADA MEDITERRANEA', 'Ensalada fresca con queso y aceitunas', 90.00, 34.00, 6, 'ENTRADA', 'LIGERO', 'BAJA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'PASTEL TRES LECHES', 'Postre clasico para eventos sociales', 65.00, 24.00, 10, 'POSTRE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'ASADO DE BODA ZACATECANO', 'Guiso tradicional de cerdo con chile rojo y especias', 210.00, 92.00, 6, 'FUERTE', 'REGIONAL', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'LOMO EN SALSA DE VINO TINTO', 'Lomo de cerdo glaseado con salsa de vino y hierbas', 235.00, 105.00, 6, 'FUERTE', 'FORMAL', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'CANAPES DE QUESO Y MEMBRILLO', 'Bocados frios para recepcion con queso regional y membrillo', 95.00, 36.00, 12, 'ENTRADA', 'REGIONAL', 'BAJA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'MOUSSE DE CHOCOLATE', 'Postre individual con chocolate semiamargo y crema batida', 80.00, 31.00, 10, 'POSTRE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');

INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'FILETE DE RES', 'GRAMOS', 'GRANEL', 'Corte fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHILE MORRON', 'PIEZAS', 'PIEZA', 'Rojo o verde');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CEBOLLA BLANCA', 'PIEZAS', 'PIEZA', 'Fresca');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'TOMATE', 'PIEZAS', 'PIEZA', 'Rojo');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'QUESO COTIJA', 'GRAMOS', 'PAQUETE', 'Queso regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'HUEVO', 'PIEZAS', 'PIEZA', 'Grande');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'BOTETE CHICO', 'GRAMOS', 'GRANEL', 'Pescado blanco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ZANAHORIA', 'PIEZAS', 'PIEZA', 'Fresca');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'APIO', 'PIEZAS', 'VARA', 'Fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'PECHUGA DE POLLO', 'PIEZAS', 'PIEZA', 'Sin piel');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CERVEZA', 'MILILITROS', 'LATA', 'Clara');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHAMPINONES', 'GRAMOS', 'LATA', 'Drenado');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'MANTEQUILLA', 'GRAMOS', 'BARRA', 'Sin sal');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ELOTE', 'GRAMOS', 'GRANEL', 'Dulce');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'LECHUGA', 'PIEZAS', 'PIEZA', 'Romana');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ACEITUNAS', 'GRAMOS', 'FRASCO', 'Sin hueso');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'HARINA', 'GRAMOS', 'BOLSA', 'Trigo');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'LECHE', 'MILILITROS', 'LITRO', 'Entera');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'AZUCAR', 'GRAMOS', 'BOLSA', 'Refinada');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'SAL', 'GRAMOS', 'GRANEL', 'Mesa');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'PIERNA DE CERDO', 'GRAMOS', 'GRANEL', 'Para asado regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHILE GUAJILLO', 'GRAMOS', 'BOLSA', 'Seco, limpio y desvenado');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHILE ANCHO', 'GRAMOS', 'BOLSA', 'Seco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'AJO', 'DIENTES', 'PIEZA', 'Fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'COMINO', 'GRAMOS', 'FRASCO', 'Molido');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'OREGANO', 'GRAMOS', 'FRASCO', 'Seco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'VINO TINTO', 'MILILITROS', 'BOTELLA', 'Para salsa');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ROMERO', 'GRAMOS', 'MANOJO', 'Fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'QUESO DE CABRA', 'GRAMOS', 'PAQUETE', 'Regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'MEMBRILLO', 'GRAMOS', 'BARRA', 'Dulce regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'PAN BAGUETTE', 'PIEZAS', 'PIEZA', 'Para canapes');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHOCOLATE SEMIAMARGO', 'GRAMOS', 'BARRA', 'Reposteria');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CREMA PARA BATIR', 'MILILITROS', 'LITRO', 'Refrigerada');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'GELATINA SIN SABOR', 'GRAMOS', 'SOBRE', 'Para mousse');

INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 1, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 2, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 3, 2);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 20, 12);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 2, 5, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 2, 6, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 2, 4, 5);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 3, 1, 1200);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 3, 12, 300);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 3, 13, 80);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 4, 7, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 4, 8, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 4, 9, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 5, 10, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 5, 11, 350);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 5, 13, 60);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 6, 14, 800);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 6, 18, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 7, 15, 3);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 7, 16, 120);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 8, 17, 400);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 8, 18, 1500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 8, 19, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 21, 1800);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 22, 120);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 23, 80);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 24, 6);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 25, 8);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 21, 1400);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 27, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 28, 20);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 13, 120);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 11, 29, 600);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 11, 30, 450);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 11, 31, 3);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 12, 32, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 12, 33, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 12, 34, 20);

-- Normalizacion del proyecto: las recetas, costos y precios se manejan por persona.
-- Las cantidades anteriores se capturaron como receta base; aqui quedan convertidas a unidad individual.
UPDATE PLATILLO_INGREDIENTE pi
SET cantidad = ROUND(
    cantidad / (
        SELECT pl.porciones_base
        FROM PLATILLO pl
        WHERE pl.id_platillo = pi.id_platillo
    ),
    3
);

UPDATE PLATILLO
SET porciones_base = 1;

INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 1, 1, 'Cortar carne y verduras en piezas uniformes.', 'Mantener tamanio similar.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 1, 2, 'Armar brochetas y asar.', 'Revisar termino de carne.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 2, 1, 'Tatemar chiles y limpiar semillas.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 2, 2, 'Rellenar, capear y freir.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 3, 1, 'Sellar filete y preparar salsa.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 4, 1, 'Condimentar pescado y cocer al vapor.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 5, 1, 'Sofreir pollo, agregar cerveza y reducir.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 9, 1, 'Cocer la pierna de cerdo hasta suavizar.', 'Reservar caldo para la salsa.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 9, 2, 'Licuar chiles, ajo y especias; guisar con la carne.', 'Reducir hasta lograr textura espesa.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 10, 1, 'Sellar el lomo y preparar reduccion de vino tinto.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 10, 2, 'Hornear con romero y banar con salsa.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 11, 1, 'Cortar baguette, montar queso de cabra y membrillo.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 12, 1, 'Fundir chocolate y mezclar con crema batida.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 12, 2, 'Refrigerar en porciones individuales.', NULL);

INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'BARRA DE BEBIDAS', 'Aguas frescas y refrescos por persona', 55.00, 'BEBIDA', 'POR_PERSONA', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'MESA DE POSTRES', 'Variedad de postres individuales', 85.00, 'POSTRE', 'POR_PERSONA', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'DECORACION FLORAL', 'Centros de mesa sencillos', 2500.00, 'MONTAJE', 'POR_EVENTO', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'SERVICIO DE MESEROS', 'Mesero adicional por evento', 900.00, 'SERVICIO', 'POR_EVENTO', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'LOZA PREMIUM', 'Loza y cristaleria elegante', 45.00, 'MONTAJE', 'POR_PERSONA', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'TORNAFIESTA', 'Antojitos para cierre de evento', 95.00, 'ALIMENTO', 'POR_PERSONA', 'S');

INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Palacio de Convenciones Zacatecas', 'Blvd. Heroes de Chapultepec S/N, Ciudad Gobierno, Zacatecas', 'Ciudad Gobierno', 'Recinto amplio para congresos, graduaciones y banquetes grandes; convenio simulado para el proyecto escolar.', 'img/salon-zacatecas-convenciones.png', 'S', 68000.00, 900, 'Operaciones Palacio', '492-491-4575', 'operaciones@convencioneszacatecas.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Hotel Emporio Zacatecas - Terraza', 'Av. Hidalgo 703, Centro Historico, Zacatecas', 'Centro Historico', 'Terraza y salones para bodas, reuniones empresariales y cenas formales en zona centrica.', 'img/salon-zacatecas-colonial.png', 'S', 42000.00, 160, 'Grupos Emporio', '492-925-6500', 'zacatecas.grupos@emporio.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Meson de Jobito - Patio Colonial', 'Jardin de la Madre 108, Centro, Zacatecas', 'Centro Historico', 'Patio colonial para recepciones medianas, bodas civiles y eventos sociales con montaje elegante.', 'img/salon-zacatecas-colonial.png', 'S', 38000.00, 180, 'Ventas Jobito', '492-924-1722', 'ventas@mesondejobito.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Corporativo La Cebada', 'Centro Historico, Zacatecas', 'Centro Historico', 'Salon con jardin y muros de cristal para bodas, XV anios y eventos sociales.', 'img/salon-zacatecas-jardin.png', 'S', 46000.00, 260, 'Coordinacion La Cebada', '492-000-2000', 'eventos@lacebada.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'La Esperanza Finca Jardin', 'Lopez de Nava 503, Zacatecas', 'Zona A', 'Finca jardin local con terraza rodeada de naturaleza para eventos familiares y recepciones.', 'img/salon-zacatecas-jardin.png', 'S', 30000.00, 120, 'Eventos La Esperanza', '492-559-2676', 'contacto@laesperanza.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'El Patio Salon de Eventos', 'Alejandro Volta 221, Zona A, Zacatecas', 'Zona A', 'Salon practico para eventos familiares, cumpleanios y reuniones privadas.', 'img/salon-zacatecas-colonial.png', 'S', 18000.00, 90, 'Administracion El Patio', '492-768-6129', 'salondeeventoselpatio@local', 'S');

INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Clasico', 'Entrada, fuerte, postre y bebidas para evento social', 420.00, 'SOCIAL', 35.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Ejecutivo', 'Servicio formal para reuniones de negocio con bebidas y meseros', 520.00, 'EMPRESARIAL', 38.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Boda Premium', 'Menu premium para bodas, bebidas, postres, loza y decoracion', 780.00, 'BODA', 45.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Ligero', 'Opciones frescas y balanceadas con bebidas', 390.00, 'LIGERO', 32.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Menu Ana Especial', 'Paquete personalizado para Ana Lopez con loza y bebidas', 610.00, 'PERSONALIZADO', 40.00, 'N', 'S', 1, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Menu Sofia Vegetariano', 'Paquete personalizado vegetariano con barra de postres', 480.00, 'PERSONALIZADO', 34.00, 'N', 'S', 2, 'S');

INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 6, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 5, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 8, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 7, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 1, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 8, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 6, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 10, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 12, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 4, 7, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 4, 4, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 5, 6, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 5, 3, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 6, 7, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 6, 2, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 11, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 10, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 11, 1);

INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 1, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 1, 3, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 2, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 2, 4, 4);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 2, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 3, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 5, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 4, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 5, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 5, 5, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 6, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 6, 2, 1);

-- Solicitudes: algunas pendientes y una convertida para evidenciar separacion.
INSERT INTO SOLICITUD_SERVICIO (id_solicitud, nombre_contacto, correo, telefono, fecha_evento, numero_invitados, id_salon_preferido, id_paquete_preferido, mensaje, estatus, fecha_solicitud, id_gerente_asignado, observaciones, origen)
VALUES (sq_solicitud.NEXTVAL, 'Rosa Martinez', 'rosa@example.com', '555-444-0001', TRUNC(SYSDATE) + 40, 140, 2, 1, 'Solicito cotizacion para cumpleanios familiar.', 'PENDIENTE', SYSDATE, NULL, NULL, 'WEB');
INSERT INTO SOLICITUD_SERVICIO (id_solicitud, nombre_contacto, correo, telefono, fecha_evento, numero_invitados, id_salon_preferido, id_paquete_preferido, mensaje, estatus, fecha_solicitud, id_gerente_asignado, observaciones, origen)
VALUES (sq_solicitud.NEXTVAL, 'Empresa Nova', 'eventos@nova.example.com', '555-444-0002', TRUNC(SYSDATE) + 20, 500, 1, 2, 'Evento corporativo grande.', 'PENDIENTE', SYSDATE, NULL, NULL, 'WEB');
INSERT INTO SOLICITUD_SERVICIO (id_solicitud, nombre_contacto, correo, telefono, fecha_evento, numero_invitados, id_salon_preferido, id_paquete_preferido, mensaje, estatus, fecha_solicitud, id_gerente_asignado, observaciones, origen)
VALUES (sq_solicitud.NEXTVAL, 'Ana Lopez', 'ana.lopez@example.com', '555-200-0001', TRUNC(SYSDATE) + 30, 110, 1, 5, 'Boda jardin.', 'CONVERTIDA', SYSDATE - 3, 2, 'Convertida en proyecto 1', 'WEB');

-- 10 proyectos activos.
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, 3, 1, 2, 1, 5, 'Boda Ana y Luis', TRUNC(SYSDATE) + 30, 110, 146100.00, 'N', 'ACTIVO', 'hash-demo-1', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 2, 2, 2, 6, 'Cena Vegetariana Sofia', TRUNC(SYSDATE) + 15, 160, 141200.00, 'N', 'ACTIVO', 'hash-demo-2', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 3, 2, 5, 1, 'Comida Ejecutiva Diego', TRUNC(SYSDATE) + 3, 70, 65750.00, 'N', 'ACTIVO', 'hash-demo-3', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 4, 1, 3, 3, 'Recepcion Valeria', TRUNC(SYSDATE) + 21, 300, 330000.00, 'S', 'ACTIVO', 'hash-demo-4', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 5, 1, 4, 2, 'Foro Andres', TRUNC(SYSDATE) + 60, 220, 176100.00, 'N', 'ACTIVO', 'hash-demo-5', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 6, 2, 1, 4, 'Bautizo Maria', TRUNC(SYSDATE) + 8, 90, 108050.00, 'N', 'ACTIVO', 'hash-demo-6', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 7, 2, 2, 1, 'Aniversario Jorge', TRUNC(SYSDATE) + 10, 180, 130000.00, 'S', 'ACTIVO', 'hash-demo-7', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 8, 1, 4, 3, 'Boda Paola', TRUNC(SYSDATE) + 18, 280, 318700.00, 'N', 'ACTIVO', 'hash-demo-8', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 9, 1, 5, 4, 'Brunch Ricardo', TRUNC(SYSDATE) + 45, 75, 63375.00, 'N', 'ACTIVO', 'hash-demo-9', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 10, 2, 3, 2, 'Convencion Elena', TRUNC(SYSDATE) + 90, 420, 283100.00, 'N', 'ACTIVO', 'hash-demo-10', SYSDATE, SYSDATE);

-- 10 proyectos realizados.
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 1, 2, 2, 3, 'Boda Realizada Ana', TRUNC(SYSDATE) - 5, 180, 218200.00, 'S', 'REALIZADO', 'hash-demo-11', SYSDATE - 20, SYSDATE - 5);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 2, 2, 1, 1, 'Cumpleanios Sofia', TRUNC(SYSDATE) - 10, 90, 113250.00, 'S', 'REALIZADO', 'hash-demo-12', SYSDATE - 30, SYSDATE - 10);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 3, 1, 5, 4, 'Desayuno Diego', TRUNC(SYSDATE) - 20, 60, 56700.00, 'S', 'REALIZADO', 'hash-demo-13', SYSDATE - 40, SYSDATE - 20);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 4, 1, 3, 3, 'Gala Valeria', TRUNC(SYSDATE) - 35, 350, 378250.00, 'S', 'REALIZADO', 'hash-demo-14', SYSDATE - 60, SYSDATE - 35);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 5, 2, 4, 2, 'Capacitacion Andres', TRUNC(SYSDATE) - 50, 200, 164600.00, 'S', 'REALIZADO', 'hash-demo-15', SYSDATE - 80, SYSDATE - 50);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 6, 2, 1, 1, 'Primera Comunion Maria', TRUNC(SYSDATE) - 70, 100, 118000.00, 'S', 'REALIZADO', 'hash-demo-16', SYSDATE - 90, SYSDATE - 70);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 7, 1, 2, 4, 'Comida Familiar Jorge', TRUNC(SYSDATE) - 90, 130, 99850.00, 'S', 'REALIZADO', 'hash-demo-17', SYSDATE - 110, SYSDATE - 90);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 8, 1, 4, 3, 'Boda Civil Paola', TRUNC(SYSDATE) - 120, 250, 289750.00, 'S', 'REALIZADO', 'hash-demo-18', SYSDATE - 145, SYSDATE - 120);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 9, 2, 5, 2, 'Reunion Ricardo', TRUNC(SYSDATE) - 150, 65, 70975.00, 'S', 'REALIZADO', 'hash-demo-19', SYSDATE - 170, SYSDATE - 150);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 10, 2, 3, 3, 'Banquete Elena', TRUNC(SYSDATE) - 200, 400, 426500.00, 'S', 'REALIZADO', 'hash-demo-20', SYSDATE - 230, SYSDATE - 200);

-- Pagos para anticipos, abonos y liquidaciones.
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 1, 25000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 2, 'ANT-001');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 2, 20000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 4, 'ANT-002');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 3, 10000.00, 'ANTICIPO', 'EFECTIVO', SYSDATE - 1, 'ANT-003');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 4, 330000.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 7, 'LIQ-004');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 5, 50000.00, 'ANTICIPO', 'TARJETA', SYSDATE - 5, 'ANT-005');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 6, 15000.00, 'ANTICIPO', 'EFECTIVO', SYSDATE - 3, 'ANT-006');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 7, 130000.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 2, 'LIQ-007');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 8, 80000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 6, 'ANT-008');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 9, 5000.00, 'ANTICIPO', 'EFECTIVO', SYSDATE - 1, 'ANT-009');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 10, 60000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 4, 'ANT-010');

INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 11, 218200.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 6, 'LIQ-011');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 12, 113250.00, 'LIQUIDACION', 'EFECTIVO', SYSDATE - 11, 'LIQ-012');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 13, 56700.00, 'LIQUIDACION', 'TARJETA', SYSDATE - 21, 'LIQ-013');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 14, 378250.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 36, 'LIQ-014');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 15, 164600.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 51, 'LIQ-015');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 16, 118000.00, 'LIQUIDACION', 'EFECTIVO', SYSDATE - 71, 'LIQ-016');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 17, 99850.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 91, 'LIQ-017');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 18, 289750.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 121, 'LIQ-018');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 19, 70975.00, 'LIQUIDACION', 'EFECTIVO', SYSDATE - 151, 'LIQ-019');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 20, 426500.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 201, 'LIQ-020');

INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 1, 1, 110, 55.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 1, 3, 1, 2500.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 3, 4, 2, 900.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 8, 2, 280, 85.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 10, 5, 420, 45.00);

INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 1, 'Laura Hernandez', 'laura.invitada@example.com', '555-777-1001', 'CONFIRMADO', SYSDATE - 1, SYSDATE);
INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 1, 'Carlos Rivera', 'carlos.invitado@example.com', '555-777-1002', 'PENDIENTE', SYSDATE - 1, NULL);
INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 2, 'Martha Salas', 'martha.invitada@example.com', '555-777-1003', 'RECHAZADO', SYSDATE - 2, SYSDATE - 1);
INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 3, 'Equipo Ventas Nova', 'ventas.invitado@example.com', '555-777-1004', 'PENDIENTE', SYSDATE, NULL);

INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'AGENDA', 'Cita de degustacion', 'Degustacion de menu regional para 2 personas. Funcion de prueba del portal cliente.', 'PENDIENTE', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'PENDIENTE', 'Lista de pendientes', 'Revisar color de manteleria, confirmar musica y entregar croquis de mesa principal.', 'PENDIENTE', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'MONTAJE', 'Preferencia de montaje', 'Mesa de novios al centro, pista despejada y recepcion con canapes.', 'LISTO', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'MUSICA', 'Momentos musicales', 'Entrada de novios, vals familiar y cierre con tornafiesta.', 'PENDIENTE', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'DIETA', 'Notas de dietas especiales', 'Considerar 4 invitados vegetarianos y 2 sin lactosa.', 'PENDIENTE', SYSDATE);

INSERT INTO NOTIFICACION VALUES (sq_notificacion.NEXTVAL, 'CLIENTE', 1, 1, NULL, 'WEB', 'Proyecto creado', 'Proyecto activo de prueba.', 'PENDIENTE', SYSDATE, NULL);
INSERT INTO NOTIFICACION VALUES (sq_notificacion.NEXTVAL, 'INSTALACION', NULL, 1, 1, 'CORREO', 'Evento confirmado', 'Preparar salon para boda.', 'PENDIENTE', SYSDATE, NULL);
INSERT INTO NOTIFICACION VALUES (sq_notificacion.NEXTVAL, 'GERENTE', 2, 2, NULL, 'WEB', 'Seguimiento de pago', 'Cliente con saldo pendiente.', 'PENDIENTE', SYSDATE, NULL);

BEGIN
    sp_generar_notificaciones_cobranza;
END;
/

COMMIT;



-- ============================================================================
-- 06 EVIDENCIAS DEL SEMESTRE
-- Archivo fuente: database\07_evidencias_sql_developer.sql
-- ============================================================================

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

ALTER TABLE tmp_evidencia_dml ADD observacion VARCHAR2(120);

INSERT INTO tmp_evidencia_dml (id, descripcion, monto)
VALUES (1, 'Registro inicial', 100);
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



-- ============================================================================
-- 07 DEMO DE TRANSACCIONES Y REGLAS
-- Archivo fuente: database\08_demo_transacciones.sql
-- ============================================================================

-- Demo breve de transacciones y reglas de negocio.
-- Ejecutar conectado como BANQUETES_CATHERINE.

SET SERVEROUTPUT ON;

DECLARE
    v_id_proyecto NUMBER;
BEGIN
    -- Este caso debe fallar porque el salon elegido tiene capacidad menor
    -- y la solicitud 2 pide 500 invitados. La transaccion se revierte.
    sp_crear_proyecto_desde_solicitud(
        p_id_solicitud => 2,
        p_id_cliente => 1,
        p_id_gerente => 2,
        p_id_salon => 6,
        p_id_paquete => 2,
        p_nombre_evento => 'Evento corporativo Nova',
        p_total_estimado => 260000,
        p_anticipo => 50000,
        p_metodo_pago => 'TRANSFERENCIA',
        p_referencia => 'DEMO-FALLA-CAPACIDAD',
        p_id_proyecto => v_id_proyecto
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error esperado de capacidad; transaccion revertida correctamente.');
END;
/

SELECT fn_salones_sugeridos(500) AS salones_sugeridos FROM dual;

BEGIN
    -- Genera notificaciones de cobranza para eventos activos no finiquitados
    -- que ocurren dentro de los siguientes 21 dias.
    sp_generar_notificaciones_cobranza;
END;
/

SELECT id_notificacion, tipo_destinatario, id_proyecto, asunto, mensaje
FROM NOTIFICACION
WHERE tipo_destinatario = 'COBRANZA'
ORDER BY fecha_creacion DESC;



-- ============================================================================
-- 08 CONSULTAS PARA EXPOSICION
-- Archivo fuente: database\10_consultas_sql_developer.sql
-- ============================================================================

-- Consultas listas para exposicion en SQL Developer.
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



-- ============================================================================
-- FIN DEL ARCHIVO MAESTRO
-- ============================================================================
SELECT 'Archivo maestro Banquetes Catherine ejecutado' AS resultado FROM dual;
