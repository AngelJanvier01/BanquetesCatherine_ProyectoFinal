# Banquetes Catherine

Proyecto final de Sistemas de Base de Datos II. Sistema web con Oracle Database para administrar solicitudes, clientes, proyectos de eventos, paquetes, pagos, salones, reportes y notificaciones.

Incluye una consola auxiliar de demostracion que registra las sentencias SQL/PLSQL ejecutadas por el sitio y muestra una tabla con las primeras filas consultadas.

## Tecnologias

- Oracle Database / SQL Developer / SQLcl
- Python 3
- Flask
- python-oracledb
- HTML, CSS y JavaScript

## Instalacion Rapida

La forma mas facil es:

```bat
instalar.bat
```

El instalador no pide conexiones ni contrasenas de Oracle. Usa `sqlplus / as sysdba`, configura `.env`, instala dependencias y reinstala solo el esquema `BANQUETES_CATHERINE`.

Para instalar y abrir en una sola accion:

```bat
abrir_proyecto.bat
```

Para reinstalar solo la base de datos demo:

```bat
reinstalar_base_datos.bat
```

El instalador no borra bases ni usuarios externos. La limpieza de `database/00_drop_schema_objects.sql` solo actua dentro del esquema `BANQUETES_CATHERINE`.

## Ejecucion

```bat
iniciar.bat
```

El script busca un puerto libre desde `5000`, inicia Flask y abre el navegador.

El puerto activo queda guardado en `.estado\puerto.txt`. Si `5000` esta ocupado, usara el siguiente libre.

Para terminar:

```bat
detener.bat
```

## Consultas Manuales En VS Code

Puedes exponer la base desde la terminal integrada de VS Code sin abrir SQL Developer.

Opcion rapida desde terminal:

```bat
abrir_sql_manual.bat
```

Eso abre SQLPlus dentro del esquema `BANQUETES_CATHERINE`. Ahi puedes escribir consultas manuales y terminar cada una con `;`.

Consultas seguras para responder al profesor:

```sql
SELECT * FROM vw_estado_pago_proyecto WHERE ROWNUM <= 5;

SELECT folio_proyecto, nombre_evento, cliente, saldo_pendiente
FROM vw_eventos_no_finiquitados_21
ORDER BY fecha_evento;

SELECT platillo, proyectos_demandados
FROM vw_popularidad_platillos
ORDER BY proyectos_demandados DESC;

SELECT nombre, precio_base AS precio_por_persona, platillos, complementos
FROM vw_paquete_resumen
ORDER BY nombre;

SELECT fn_total_estimado_evento(120, 2, 1) AS total_evento
FROM dual;
```

Si estas en VS Code tambien puedes usar `Terminal > Run Task` y elegir:

- `BD: abrir SQL manual`
- `BD: ejecutar consultas demo`
- `BD: reinstalar datos demo`
- `App: iniciar`
- `App: detener`

Para ejecutar una bateria completa de consultas:

```bat
ejecutar_consultas_demo.bat
```

El resultado queda guardado en `.estado\consultas_demo.log`.

## Configuracion

Edita `.env` si tu Oracle usa otro host, puerto o servicio:

```txt
ORACLE_HOST=127.0.0.1
ORACLE_PORT=1521
ORACLE_SERVICE=AUTO
ORACLE_USER=BANQUETES_CATHERINE
ORACLE_PASSWORD=Catherine2026
ORACLE_USAR_SYSDBA_LOCAL=S
ORACLE_CLIENT_LIB_DIR=AUTO
```

Con `ORACLE_SERVICE=AUTO`, el proyecto detecta automaticamente el PDB local abierto (`XEPDB1`, `FREEPDB1` u otro PDB disponible) cuando usa `ORACLE_USAR_SYSDBA_LOCAL=S`.

Si prefieres conectar por listener normal, cambia `ORACLE_USAR_SYSDBA_LOCAL=N` y escribe el servicio real:

```txt
ORACLE_SERVICE=XEPDB1
```

Para cargar la base sin listener:

```bat
sqlplus / as sysdba @database/98_instalar_local_sysdba.sql
```

## Usuarios Demo

| Rol | Usuario | Contrasena |
| --- | --- | --- |
| GERENTE_ADMIN | admin.catherine | admin123 |
| GERENTE | gerente.lucia | gerente123 |
| CLIENTE | cliente.demo | cliente123 |
| CHEF | chef.renata | gerente123 |

## Scripts SQL

Ejecutar en este orden si usas SQL Developer manualmente:

```sql
@database/01_crear_usuario_opcional.sql -- como SYS/SYSTEM, opcional
@database/99_instalar_todo.sql          -- como BANQUETES_CATHERINE
```

Scripts principales:

- `00_drop_schema_objects.sql`: limpieza segura del esquema.
- `01_crear_usuario_opcional.sql`: crea `BANQUETES_CATHERINE`.
- `02_schema.sql`: tablas, restricciones y `ALTER TABLE`.
- `03_secuencias_indices.sql`: secuencias e indices.
- `04_vistas_sinonimos.sql`: vistas y sinonimos.
- `05_funciones_procedimientos.sql`: funciones y procedimientos PL/SQL.
- `06_datos_prueba.sql`: datos de prueba, 10 proyectos activos y 10 realizados.
- `07_evidencias_sql_developer.sql`: evidencias del temario.
- `08_demo_transacciones.sql`: pruebas de reglas y transacciones.

## Flujo De Demostracion

Abre tambien la consola auxiliar en otra ventana:

```txt
http://127.0.0.1:PUERTO/consola-sql
```

Reemplaza `PUERTO` por el valor de `.estado\puerto.txt`.

Esa vista muestra las consultas SQL, procedimientos PL/SQL, parametros seguros, filas devueltas, muestra de resultados en tabla, errores y commits/rollbacks que genera el sitio.

1. Ver inicio sin cargar catalogos.
2. Abrir catalogos publicos separados: platillos, complementos y salones.
3. Crear una solicitud desde el modal Agendar.
4. Entrar como gerente.
5. Modificar una solicitud propuesta por cliente.
6. Convertir solicitud en proyecto con anticipo.
7. Intentar convertir una solicitud con salon sin capacidad.
8. Registrar pago y revisar saldo pendiente.
9. Liquidar un evento y ver `finiquitado = S`.
10. Entrar como cliente.
11. Ver solicitudes, costos, ubicacion y paquetes visibles.
12. Cambiar invitados en un evento permitido.
13. Intentar cambiar invitados en evento con menos de 5 dias.
14. Simular envio de invitacion y confirmar invitado.
15. Entrar como chef y administrar recetas, ingredientes, dificultad y costos.
16. Revisar reporte de ingredientes.
17. Revisar cobranza 21 dias antes.
18. Revisar platillos populares y menos demandados.
19. Revisar historial del cliente.
20. Revisar notificaciones generadas.

## Temas Del Semestre Cubiertos

- Diseno entidad-relacion y 3FN.
- `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`.
- Restricciones `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `CHECK`, `NOT NULL`.
- Secuencias Oracle.
- Indices.
- Vistas.
- Sinonimos.
- `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`.
- `COMMIT`, `ROLLBACK`, `SAVEPOINT`.
- `SELECT`, `FROM`, `WHERE`, `ORDER BY`.
- Funciones Oracle de texto, fecha y matematicas.
- `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`.
- `UNION`, `UNION ALL`, `INTERSECT`, `MINUS`.
- Funciones PL/SQL.
- Procedimientos PL/SQL con DML y transacciones.

## Notas De Seguridad

- Las contrasenas de usuarios demo se guardan con hash PBKDF2.
- Los paquetes personalizados tienen `visible_publico = 'N'`, `personalizado = 'S'` e `id_cliente` obligatorio.
- Solo `GERENTE_ADMIN` puede cambiar estatus de gerentes.
- Las reglas criticas viven en PL/SQL, no solo en la interfaz web.
