-- Wrapper no interactivo para ejecutar consultas preparadas.
-- Ejecutar con: sqlplus / as sysdba @database/96_ejecutar_consultas_demo.sql

WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT SQL.SQLCODE

SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 120

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

    DBMS_OUTPUT.PUT_LINE('PDB usado: ' || v_pdb);
    EXECUTE IMMEDIATE 'ALTER SESSION SET CONTAINER = ' || DBMS_ASSERT.SIMPLE_SQL_NAME(v_pdb);
END;
/

ALTER SESSION SET CURRENT_SCHEMA = BANQUETES_CATHERINE;

@@09_consultas_para_exponer.sql

EXIT SUCCESS
