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
        p_porciones_base,
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
