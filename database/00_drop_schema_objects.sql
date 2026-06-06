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
            'NOTIFICACION', 'INVITADO_EVENTO', 'PAGO', 'PROYECTO_COMPLEMENTO', 'PROYECTO_EVENTO',
            'SOLICITUD_SERVICIO', 'PAQUETE_PLATILLO', 'PAQUETE', 'SALON',
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
