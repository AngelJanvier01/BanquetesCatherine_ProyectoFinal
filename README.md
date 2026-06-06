# Banquetes Catherine

Proyecto final de Sistemas de Base de Datos II. Sistema web con Oracle Database para administrar solicitudes, clientes, proyectos de eventos, paquetes, pagos, salones, reportes y notificaciones.

## Tecnologias

- Oracle Database / SQL Developer / SQLcl
- Python 3
- Flask
- python-oracledb
- HTML, CSS y JavaScript

## Instalacion Rapida

1. Ejecuta:

```bat
instalar.bat
```

2. El instalador crea `.venv`, instala dependencias y busca SQLcl con `winget`.

3. Si deseas cargar Oracle desde el instalador, responde `S` cuando pregunte por scripts SQL.

4. Para crear el usuario del proyecto, usa una conexion administrativa:

```txt
sys/TuClave@//127.0.0.1:1521/XEPDB1 as sysdba
```

5. Para instalar objetos del proyecto:

```txt
BANQUETES_CATHERINE/Catherine2026@//127.0.0.1:1521/XEPDB1
```

El instalador no borra bases ni usuarios externos. La limpieza de `database/00_drop_schema_objects.sql` solo actua dentro del esquema conectado.

## Ejecucion

```bat
iniciar.bat
```

El script busca un puerto libre desde `5000`, inicia Flask y abre el navegador.

Para terminar:

```bat
detener.bat
```

## Configuracion

Edita `.env` si tu Oracle usa otro host, puerto o servicio:

```txt
ORACLE_HOST=127.0.0.1
ORACLE_PORT=1521
ORACLE_SERVICE=XEPDB1
ORACLE_USER=BANQUETES_CATHERINE
ORACLE_PASSWORD=Catherine2026
```

## Usuarios Demo

| Rol | Usuario | Contrasena |
| --- | --- | --- |
| GERENTE_ADMIN | admin.catherine | admin123 |
| GERENTE | gerente.lucia | gerente123 |
| CLIENTE | cliente.demo | cliente123 |

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

1. Ver catalogos publicos de platillos, complementos y salones.
2. Crear una solicitud publica.
3. Entrar como gerente.
4. Convertir solicitud en proyecto con anticipo.
5. Intentar convertir una solicitud con salon sin capacidad.
6. Registrar pago y revisar saldo pendiente.
7. Liquidar un evento y ver `finiquitado = S`.
8. Entrar como cliente.
9. Cambiar invitados en un evento permitido.
10. Intentar cambiar invitados en evento con menos de 5 dias.
11. Revisar reporte de ingredientes.
12. Revisar cobranza 21 dias antes.
13. Revisar platillos populares y menos demandados.
14. Revisar historial del cliente.
15. Revisar notificaciones generadas.

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
