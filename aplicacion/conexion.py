import os
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
    carpeta_cliente = os.getenv("ORACLE_CLIENT_LIB_DIR", r"C:\app\ANGEL\product\21c\dbhomeXE\bin")
    try:
        oracledb.init_oracle_client(lib_dir=carpeta_cliente)
    except oracledb.ProgrammingError:
        pass
    cliente_oracle_iniciado = True


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
            cursor.execute(f"ALTER SESSION SET CONTAINER = {os.getenv('ORACLE_SERVICE', 'XEPDB1')}")
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
