-- Instalacion local sin listener TCP.
-- Ejecutar con: sqlplus / as sysdba @98_instalar_local_sysdba.sql
-- Sirve cuando Oracle XE en Windows marca ORA-12518 por el listener.

WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT SQL.SQLCODE

SET ECHO OFF
SET FEEDBACK ON
SET HEADING ON
SET SERVEROUTPUT ON

DECLARE
    v_pdb VARCHAR2(128);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ALL OPEN';
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    SELECT name
    INTO v_pdb
    FROM (
        SELECT name
        FROM v$pdbs
        WHERE open_mode = 'READ WRITE'
        ORDER BY
            CASE
                WHEN name = 'XEPDB1' THEN 1
                WHEN name = 'FREEPDB1' THEN 2
                ELSE 3
            END,
            name
    )
    WHERE ROWNUM = 1;

    DBMS_OUTPUT.PUT_LINE('PDB_USADO=' || v_pdb);
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_pdb);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20990, 'No se encontro un PDB abierto. Abre Oracle XE/Free y verifica XEPDB1 o FREEPDB1.');
END;
/

@@01_crear_usuario_opcional.sql

ALTER SESSION SET CURRENT_SCHEMA = BANQUETES_CATHERINE;

SELECT 'PDB_USADO=' || SYS_CONTEXT('USERENV', 'CON_NAME') AS pdb_detectado FROM dual;

@@00_drop_schema_objects.sql
@@02_schema.sql
@@03_secuencias_indices.sql
@@04_vistas_sinonimos.sql
@@05_funciones_procedimientos.sql
@@06_datos_prueba.sql

SELECT 'Instalacion local SYSDBA completada en BANQUETES_CATHERINE' AS resultado FROM dual;

EXIT SUCCESS
