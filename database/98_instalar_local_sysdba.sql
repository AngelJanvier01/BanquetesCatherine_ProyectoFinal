-- Instalacion local sin listener TCP.
-- Ejecutar con: sqlplus / as sysdba @98_instalar_local_sysdba.sql
-- Sirve cuando Oracle XE en Windows marca ORA-12518 por el listener.

ALTER SESSION SET CONTAINER = XEPDB1;

@@01_crear_usuario_opcional.sql

ALTER SESSION SET CURRENT_SCHEMA = BANQUETES_CATHERINE;

@@00_drop_schema_objects.sql
@@02_schema.sql
@@03_secuencias_indices.sql
@@04_vistas_sinonimos.sql
@@05_funciones_procedimientos.sql
@@06_datos_prueba.sql

SELECT 'Instalacion local SYSDBA completada en BANQUETES_CATHERINE' AS resultado FROM dual;
