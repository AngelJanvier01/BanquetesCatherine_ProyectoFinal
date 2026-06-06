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
