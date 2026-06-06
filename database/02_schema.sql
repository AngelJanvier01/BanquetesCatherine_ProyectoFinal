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
    CONSTRAINT ck_usuario_rol CHECK (rol IN ('CLIENTE', 'GERENTE', 'GERENTE_ADMIN')),
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
    porciones_base NUMBER DEFAULT 4 NOT NULL,
    categoria VARCHAR2(60),
    tipo_dieta VARCHAR2(60),
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT uq_platillo_nombre UNIQUE (nombre),
    CONSTRAINT ck_platillo_precio CHECK (precio >= 0),
    CONSTRAINT ck_platillo_porciones CHECK (porciones_base > 0),
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
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT uq_complemento_nombre UNIQUE (nombre),
    CONSTRAINT ck_complemento_precio CHECK (precio >= 0),
    CONSTRAINT ck_complemento_activo CHECK (activo IN ('S', 'N'))
);

CREATE TABLE SALON (
    id_salon NUMBER PRIMARY KEY,
    nombre VARCHAR2(150) NOT NULL,
    direccion VARCHAR2(250) NOT NULL,
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
    visible_publico CHAR(1) DEFAULT 'S' NOT NULL,
    personalizado CHAR(1) DEFAULT 'N' NOT NULL,
    id_cliente NUMBER,
    activo CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT fk_paquete_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
    CONSTRAINT uq_paquete_nombre_cliente UNIQUE (nombre, id_cliente),
    CONSTRAINT ck_paquete_precio CHECK (precio_base >= 0),
    CONSTRAINT ck_paquete_visible CHECK (visible_publico IN ('S', 'N')),
    CONSTRAINT ck_paquete_personalizado CHECK (personalizado IN ('S', 'N')),
    CONSTRAINT ck_paquete_activo CHECK (activo IN ('S', 'N')),
    CONSTRAINT ck_paquete_privado CHECK (
        personalizado = 'N'
        OR (personalizado = 'S' AND visible_publico = 'N' AND id_cliente IS NOT NULL)
    )
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
