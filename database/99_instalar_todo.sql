-- Instalador completo para SQL Developer o SQLcl.
-- Ejecutar conectado como BANQUETES_CATHERINE desde la carpeta database.

@00_drop_schema_objects.sql
@02_schema.sql
@03_secuencias_indices.sql
@04_vistas_sinonimos.sql
@05_funciones_procedimientos.sql
@06_datos_prueba.sql

SELECT 'Instalacion de Banquetes Catherine completada' AS resultado FROM dual;

