import os
from contextlib import contextmanager

import oracledb
from dotenv import load_dotenv


load_dotenv()


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


def consultar(sql, parametros=None):
    with abrir_conexion() as conexion:
        with conexion.cursor() as cursor:
            cursor.execute(sql, parametros or {})
            return filas_como_diccionarios(cursor)


def ejecutar(sql, parametros=None):
    with abrir_conexion() as conexion:
        with conexion.cursor() as cursor:
            cursor.execute(sql, parametros or {})
        conexion.commit()

