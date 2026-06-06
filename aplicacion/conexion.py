import os
import re
import shutil
from contextlib import contextmanager

import oracledb
from dotenv import load_dotenv

try:
    from .monitor_sql import registrar_evento_sql
except ImportError:
    from monitor_sql import registrar_evento_sql


load_dotenv()

cliente_oracle_iniciado = False


def usar_sysdba_local():
    return os.getenv("ORACLE_USAR_SYSDBA_LOCAL", "N").upper() == "S"


def iniciar_cliente_oracle():
    global cliente_oracle_iniciado
    if cliente_oracle_iniciado:
        return
    carpeta_cliente = os.getenv("ORACLE_CLIENT_LIB_DIR", "AUTO").strip()
    if carpeta_cliente.upper() in ("", "AUTO"):
        ruta_sqlplus = shutil.which("sqlplus")
        carpeta_cliente = os.path.dirname(ruta_sqlplus) if ruta_sqlplus else ""
    try:
        if carpeta_cliente and os.path.isdir(carpeta_cliente):
            oracledb.init_oracle_client(lib_dir=carpeta_cliente)
        else:
            oracledb.init_oracle_client()
    except oracledb.ProgrammingError:
        pass
    cliente_oracle_iniciado = True


def nombre_oracle_seguro(nombre):
    return bool(re.match(r"^[A-Za-z][A-Za-z0-9_$#]*$", nombre or ""))


def seleccionar_pdb_local(cursor):
    servicio = os.getenv("ORACLE_SERVICE", "AUTO").strip()
    if servicio and servicio.upper() != "AUTO":
        if not nombre_oracle_seguro(servicio):
            raise ValueError("ORACLE_SERVICE contiene un nombre no valido.")
        try:
            cursor.execute(f"ALTER SESSION SET CONTAINER = {servicio}")
            return servicio
        except oracledb.DatabaseError:
            pass

    cursor.execute(
        """
        BEGIN
            BEGIN
                EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE ALL OPEN';
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
        END;
        """
    )
    cursor.execute(
        """
        SELECT name
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
        WHERE ROWNUM = 1
        """
    )
    fila = cursor.fetchone()
    if not fila:
        raise RuntimeError("No se encontro un PDB abierto para Oracle local.")
    pdb = fila[0]
    if not nombre_oracle_seguro(pdb):
        raise ValueError("El PDB detectado no tiene un nombre valido.")
    cursor.execute(f"ALTER SESSION SET CONTAINER = {pdb}")
    return pdb


def obtener_dsn():
    dsn_directo = os.getenv("ORACLE_DSN")
    if dsn_directo:
        return dsn_directo

    servidor = os.getenv("ORACLE_HOST", "127.0.0.1")
    puerto = int(os.getenv("ORACLE_PORT", "1521"))
    servicio = os.getenv("ORACLE_SERVICE", "FREEPDB1")
    return oracledb.makedsn(servidor, puerto, service_name=servicio)


@contextmanager
def abrir_conexion():
    if usar_sysdba_local():
        iniciar_cliente_oracle()
        conexion = oracledb.connect(mode=oracledb.AUTH_MODE_SYSDBA)
        with conexion.cursor() as cursor:
            seleccionar_pdb_local(cursor)
            cursor.execute(f"ALTER SESSION SET CURRENT_SCHEMA = {os.getenv('ORACLE_USER', 'BANQUETES_CATHERINE')}")
    else:
        conexion = oracledb.connect(
            user=os.getenv("ORACLE_USER", "BANQUETES_CATHERINE"),
            password=os.getenv("ORACLE_PASSWORD", "Catherine2026"),
            dsn=obtener_dsn(),
        )
    try:
        yield conexion
    finally:
        conexion.close()


def filas_como_diccionarios(cursor):
    columnas = [columna[0].lower() for columna in cursor.description]
    return [dict(zip(columnas, fila)) for fila in cursor.fetchall()]


def consultar(sql, parametros=None, accion="Consulta SQL"):
    with abrir_conexion() as conexion:
        with conexion.cursor() as cursor:
            try:
                cursor.execute(sql, parametros or {})
                filas = filas_como_diccionarios(cursor)
                registrar_evento_sql(
                    accion=accion,
                    sentencia=sql,
                    parametros=parametros,
                    filas=len(filas),
                    resultado=f"{len(filas)} fila(s) consultada(s)",
                    muestra=filas[:10],
                )
                return filas
            except Exception as error:
                registrar_evento_sql(
                    accion=accion,
                    sentencia=sql,
                    parametros=parametros,
                    error=error,
                    resultado="Error en consulta",
                )
                raise


def ejecutar(sql, parametros=None, accion="Ejecucion SQL"):
    with abrir_conexion() as conexion:
        with conexion.cursor() as cursor:
            try:
                cursor.execute(sql, parametros or {})
                filas_afectadas = cursor.rowcount
                registrar_evento_sql(
                    accion=accion,
                    sentencia=sql,
                    parametros=parametros,
                    filas=filas_afectadas,
                    resultado=f"{filas_afectadas} fila(s) afectada(s); COMMIT",
                )
            except Exception as error:
                registrar_evento_sql(
                    accion=accion,
                    sentencia=sql,
                    parametros=parametros,
                    error=error,
                    resultado="Error; ROLLBACK",
                )
                raise
        conexion.commit()


def registrar_procedimiento(accion, nombre_procedimiento, parametros=None, resultado=None, error=None):
    nombres = ", ".join([f":p{i + 1}" for i in range(len(parametros or []))])
    sentencia = f"BEGIN {nombre_procedimiento}({nombres}); END;"
    registrar_evento_sql(
        accion=accion,
        sentencia=sentencia,
        parametros=parametros,
        resultado=resultado,
        error=error,
        tipo="PL/SQL",
    )
