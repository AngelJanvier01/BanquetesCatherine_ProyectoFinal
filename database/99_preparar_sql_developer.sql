-- Habilita conexion compartida para SQL Developer cuando Oracle XE en Windows
-- falla con ORA-12518 al entregar conexiones dedicadas.

SET SERVEROUTPUT ON

DECLARE
    v_servicio VARCHAR2(128);
BEGIN
    SELECT LOWER(name)
    INTO v_servicio
    FROM (
        SELECT name
        FROM v$pdbs
        WHERE open_mode = 'READ WRITE'
          AND name <> 'PDB$SEED'
        ORDER BY CASE WHEN name = 'XEPDB1' THEN 0 WHEN name = 'FREEPDB1' THEN 1 ELSE 2 END, name
    )
    WHERE ROWNUM = 1;

    EXECUTE IMMEDIATE 'ALTER SYSTEM SET shared_servers = 5 SCOPE=BOTH';
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET dispatchers = ''(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1))(DISPATCHERS=2)(SERVICE=' || v_servicio || ')'' SCOPE=BOTH';
    EXECUTE IMMEDIATE 'ALTER SYSTEM REGISTER';

    DBMS_OUTPUT.PUT_LINE('Servicio preparado para SQL Developer: ' || v_servicio);
END;
/

EXIT
