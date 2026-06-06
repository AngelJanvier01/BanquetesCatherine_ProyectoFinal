-- Limpieza segura: ejecutar conectado como BANQUETES_CATHERINE.
-- No elimina usuarios ni objetos fuera del esquema actual.

BEGIN
    FOR obj IN (
        SELECT object_name, object_type
        FROM user_objects
        WHERE object_type IN ('VIEW', 'SYNONYM', 'PROCEDURE', 'FUNCTION')
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ' || obj.object_type || ' "' || obj.object_name || '"';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

BEGIN
    FOR tbl IN (
        SELECT table_name
        FROM user_tables
        WHERE table_name IN (
            'NOTIFICACION', 'PAGO', 'PROYECTO_COMPLEMENTO', 'PROYECTO_EVENTO',
            'SOLICITUD_SERVICIO', 'PAQUETE_PLATILLO', 'PAQUETE', 'SALON',
            'COMPLEMENTO', 'INSTRUCCION', 'PLATILLO_INGREDIENTE', 'INGREDIENTE',
            'PLATILLO', 'GERENTE', 'CLIENTE', 'USUARIO'
        )
        ORDER BY table_name
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE "' || tbl.table_name || '" CASCADE CONSTRAINTS';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

BEGIN
    FOR seq IN (SELECT sequence_name FROM user_sequences) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE "' || seq.sequence_name || '"';
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

