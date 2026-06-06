import json
import os
import threading
from datetime import datetime
from decimal import Decimal


_bloqueo = threading.Lock()
_maximo_eventos = 300


def ruta_log_sql():
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    carpeta_estado = os.path.join(raiz, ".estado")
    os.makedirs(carpeta_estado, exist_ok=True)
    return os.path.join(carpeta_estado, "monitor_sql.jsonl")


def valor_seguro(valor):
    if valor is None:
        return None
    if isinstance(valor, Decimal):
        return float(valor)
    elif isinstance(valor, datetime):
        return valor.strftime("%Y-%m-%d %H:%M:%S")
    elif hasattr(valor, "getvalue"):
        return "<parametro_salida>"
    elif isinstance(valor, dict):
        return {clave: valor_seguro(item) for clave, item in valor.items()}
    elif isinstance(valor, (list, tuple)):
        return [valor_seguro(item) for item in valor]
    elif isinstance(valor, (int, float, str, bool)):
        texto = str(valor)
    else:
        texto = str(valor)

    if len(texto) > 140:
        texto = texto[:137] + "..."
    return texto


def parametros_seguros(parametros):
    if not parametros:
        return {}
    if isinstance(parametros, dict):
        return {clave: valor_seguro(valor) for clave, valor in parametros.items() if "contrasena" not in clave.lower() and "password" not in clave.lower()}
    return [valor_seguro(valor) for valor in parametros]


def muestra_segura(muestra):
    if not muestra:
        return []
    filas = []
    for fila in muestra:
        if isinstance(fila, dict):
            filas.append({
                clave: "***" if "contrasena" in clave.lower() or "password" in clave.lower() or "hash" in clave.lower() else valor_seguro(valor)
                for clave, valor in fila.items()
            })
        else:
            filas.append(valor_seguro(fila))
    return filas


def limpiar_sql(sql):
    return " ".join(str(sql).strip().split())


def registrar_evento_sql(accion, sentencia, parametros=None, filas=None, resultado=None, error=None, tipo="SQL", muestra=None):
    evento = {
        "hora": datetime.now().strftime("%H:%M:%S"),
        "fecha": datetime.now().strftime("%Y-%m-%d"),
        "accion": accion,
        "tipo": tipo,
        "sentencia": limpiar_sql(sentencia),
        "parametros": parametros_seguros(parametros),
        "filas": filas,
        "resultado": resultado,
        "error": str(error) if error else None,
        "muestra": muestra_segura(muestra),
    }

    with _bloqueo:
        ruta = ruta_log_sql()
        eventos = leer_eventos_sql(limite=_maximo_eventos - 1)
        eventos.append(evento)
        with open(ruta, "w", encoding="utf-8") as archivo:
            for item in eventos:
                archivo.write(json.dumps(item, ensure_ascii=False) + "\n")


def leer_eventos_sql(limite=120):
    ruta = ruta_log_sql()
    if not os.path.exists(ruta):
        return []
    with open(ruta, "r", encoding="utf-8") as archivo:
        lineas = archivo.readlines()[-limite:]
    eventos = []
    for linea in lineas:
        try:
            eventos.append(json.loads(linea))
        except json.JSONDecodeError:
            continue
    return eventos


def limpiar_eventos_sql():
    ruta = ruta_log_sql()
    with _bloqueo:
        with open(ruta, "w", encoding="utf-8") as archivo:
            archivo.write("")
