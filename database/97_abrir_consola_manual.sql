-- Consola manual para exposicion.
-- Ejecutar con: sqlplus / as sysdba @database/97_abrir_consola_manual.sql
-- No termina SQLPlus; deja la sesion lista para escribir consultas manuales.

SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 100
SET SQLPROMPT "BANQUETES_CATHERINE> "

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

PROMPT
PROMPT ============================================================
PROMPT  Consola manual lista
PROMPT ============================================================
PROMPT  Escribe consultas como estas y termina cada una con punto y coma:
PROMPT
PROMPT  SELECT * FROM vw_estado_pago_proyecto WHERE ROWNUM <= 5;
PROMPT  SELECT * FROM vw_eventos_no_finiquitados_21;
PROMPT  SELECT platillo, proyectos_demandados FROM vw_popularidad_platillos ORDER BY proyectos_demandados DESC;
PROMPT
PROMPT  Para salir escribe: EXIT
PROMPT ============================================================
PROMPT
