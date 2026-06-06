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
