import base64
import hashlib
import hmac
from functools import wraps

from flask import flash, redirect, session, url_for


def generar_hash_contrasena(contrasena, sal="banquetes2026", iteraciones=260000):
    derivado = hashlib.pbkdf2_hmac(
        "sha256",
        contrasena.encode("utf-8"),
        sal.encode("utf-8"),
        iteraciones,
    )
    hash_base64 = base64.b64encode(derivado).decode("utf-8")
    return f"pbkdf2_sha256${iteraciones}${sal}${hash_base64}"


def verificar_contrasena(contrasena, hash_guardado):
    try:
        algoritmo, iteraciones, sal, hash_base64 = hash_guardado.split("$", 3)
        if algoritmo != "pbkdf2_sha256":
            return False
        derivado = hashlib.pbkdf2_hmac(
            "sha256",
            contrasena.encode("utf-8"),
            sal.encode("utf-8"),
            int(iteraciones),
        )
        return hmac.compare_digest(base64.b64encode(derivado).decode("utf-8"), hash_base64)
    except Exception:
        return False


def sesion_requerida(*roles_permitidos):
    def decorador(funcion):
        @wraps(funcion)
        def envoltura(*args, **kwargs):
            if "id_usuario" not in session:
                flash("Inicia sesion para continuar.", "aviso")
                return redirect(url_for("login"))
            if roles_permitidos and session.get("rol") not in roles_permitidos:
                flash("No tienes permiso para entrar a esta seccion.", "error")
                return redirect(url_for("inicio"))
            return funcion(*args, **kwargs)

        return envoltura

    return decorador
