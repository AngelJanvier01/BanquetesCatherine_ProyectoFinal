from datetime import datetime
import os

import oracledb
from flask import Flask, flash, redirect, render_template, request, session, url_for

try:
    from .conexion import abrir_conexion, consultar
    from .seguridad import sesion_requerida, verificar_contrasena
except ImportError:
    from conexion import abrir_conexion, consultar
    from seguridad import sesion_requerida, verificar_contrasena


app = Flask(
    __name__,
    template_folder="plantillas",
    static_folder="estatico",
)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "banquetes-catherine-demo")


def obtener_catalogos():
    datos = {
        "platillos": [],
        "complementos": [],
        "salones": [],
        "paquetes": [],
        "error_bd": None,
    }
    try:
        datos["platillos"] = consultar("SELECT * FROM vw_platillos_publicos ORDER BY nombre")
        datos["complementos"] = consultar("SELECT * FROM vw_complementos_publicos ORDER BY nombre")
        datos["salones"] = consultar("SELECT * FROM vw_salones_publicos ORDER BY capacidad_maxima")
        datos["paquetes"] = consultar("SELECT * FROM vw_paquetes_publicos ORDER BY precio_base")
    except Exception as error:
        datos["error_bd"] = str(error)
    return datos


@app.route("/")
def inicio():
    return render_template("inicio.html", **obtener_catalogos())


@app.post("/solicitudes")
def crear_solicitud():
    try:
        fecha_evento = datetime.strptime(request.form["fecha_evento"], "%Y-%m-%d")
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_solicitud = cursor.var(oracledb.NUMBER)
                cursor.callproc(
                    "sp_crear_solicitud",
                    [
                        request.form["nombre_contacto"],
                        request.form["correo"],
                        request.form.get("telefono"),
                        fecha_evento,
                        int(request.form["numero_invitados"]),
                        int(request.form["id_salon_preferido"]) if request.form.get("id_salon_preferido") else None,
                        int(request.form["id_paquete_preferido"]) if request.form.get("id_paquete_preferido") else None,
                        request.form.get("mensaje"),
                        id_solicitud,
                    ],
                )
        flash(f"Solicitud registrada con folio {int(id_solicitud.getvalue())}.", "exito")
    except Exception as error:
        flash(f"No se pudo registrar la solicitud: {error}", "error")
    return redirect(url_for("inicio"))


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "GET":
        return render_template("login.html")

    nombre_usuario = request.form["nombre_usuario"].strip().lower()
    contrasena = request.form["contrasena"]

    usuarios = consultar(
        """
        SELECT id_usuario, nombre_usuario, hash_contrasena, rol
        FROM USUARIO
        WHERE LOWER(nombre_usuario) = :nombre_usuario
          AND activo = 'S'
        """,
        {"nombre_usuario": nombre_usuario},
    )

    if not usuarios or not verificar_contrasena(contrasena, usuarios[0]["hash_contrasena"]):
        flash("Usuario o contrasena incorrectos.", "error")
        return redirect(url_for("login"))

    usuario = usuarios[0]
    session.clear()
    session["id_usuario"] = usuario["id_usuario"]
    session["nombre_usuario"] = usuario["nombre_usuario"]
    session["rol"] = usuario["rol"]

    if usuario["rol"] == "CLIENTE":
        return redirect(url_for("panel_cliente"))
    return redirect(url_for("panel_gerente"))


@app.get("/salir")
def salir():
    session.clear()
    flash("Sesion cerrada.", "aviso")
    return redirect(url_for("inicio"))


@app.get("/cliente")
@sesion_requerida("CLIENTE")
def panel_cliente():
    proyectos = consultar(
        """
        SELECT *
        FROM vw_proyectos_cliente
        WHERE id_usuario = :id_usuario
          AND estatus = 'ACTIVO'
        ORDER BY fecha_evento
        """,
        {"id_usuario": session["id_usuario"]},
    )
    paquetes = consultar(
        """
        SELECT id_paquete, nombre, descripcion, precio_base, visible_publico, personalizado
        FROM PAQUETE
        WHERE activo = 'S'
          AND (
                visible_publico = 'S'
                OR id_cliente = (SELECT id_cliente FROM CLIENTE WHERE id_usuario = :id_usuario)
              )
        ORDER BY personalizado DESC, nombre
        """,
        {"id_usuario": session["id_usuario"]},
    )
    notificaciones = consultar(
        """
        SELECT *
        FROM NOTIFICACION
        WHERE tipo_destinatario = 'CLIENTE'
          AND id_destinatario = (SELECT id_cliente FROM CLIENTE WHERE id_usuario = :id_usuario)
        ORDER BY fecha_creacion DESC
        """,
        {"id_usuario": session["id_usuario"]},
    )
    return render_template("cliente.html", proyectos=proyectos, paquetes=paquetes, notificaciones=notificaciones)


@app.post("/cliente/proyectos/<int:id_proyecto>/invitados")
@sesion_requerida("CLIENTE")
def actualizar_invitados(id_proyecto):
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.callproc(
                    "sp_actualizar_invitados",
                    [session["id_usuario"], id_proyecto, int(request.form["numero_invitados"])],
                )
        flash("Numero de invitados actualizado.", "exito")
    except Exception as error:
        flash(f"No se pudo actualizar invitados: {error}", "error")
    return redirect(url_for("panel_cliente"))


@app.get("/gerente")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def panel_gerente():
    solicitudes = consultar("SELECT * FROM vw_solicitudes_pendientes ORDER BY fecha_solicitud")
    proyectos = consultar(
        """
        SELECT pe.id_proyecto, pe.nombre_evento, pe.fecha_evento, pe.numero_invitados,
               c.nombre || ' ' || c.apellido AS cliente, s.nombre AS salon,
               ep.total_estimado, ep.total_pagado, ep.saldo_pendiente, pe.estatus, pe.finiquitado
        FROM PROYECTO_EVENTO pe
        INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
        INNER JOIN SALON s ON s.id_salon = pe.id_salon
        INNER JOIN vw_estado_pago_proyecto ep ON ep.id_proyecto = pe.id_proyecto
        WHERE pe.estatus = 'ACTIVO'
        ORDER BY pe.fecha_evento
        """
    )
    clientes = consultar("SELECT id_cliente, nombre || ' ' || apellido AS cliente FROM CLIENTE ORDER BY cliente")
    gerentes = consultar("SELECT id_gerente, nombre, estatus FROM GERENTE ORDER BY nombre")
    salones = consultar("SELECT id_salon, nombre, capacidad_maxima FROM SALON WHERE activo = 'S' ORDER BY capacidad_maxima")
    paquetes = consultar("SELECT id_paquete, nombre, personalizado, id_cliente FROM PAQUETE WHERE activo = 'S' ORDER BY nombre")
    platillos = consultar("SELECT id_platillo, nombre FROM PLATILLO WHERE activo = 'S' ORDER BY nombre")
    return render_template(
        "gerente.html",
        solicitudes=solicitudes,
        proyectos=proyectos,
        clientes=clientes,
        gerentes=gerentes,
        salones=salones,
        paquetes=paquetes,
        platillos=platillos,
    )


@app.post("/gerente/solicitudes/<int:id_solicitud>/convertir")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def convertir_solicitud(id_solicitud):
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_proyecto = cursor.var(oracledb.NUMBER)
                cursor.callproc(
                    "sp_crear_proyecto_desde_solicitud",
                    [
                        id_solicitud,
                        int(request.form["id_cliente"]),
                        int(request.form["id_gerente"]),
                        int(request.form["id_salon"]),
                        int(request.form["id_paquete"]),
                        request.form["nombre_evento"],
                        float(request.form["total_estimado"]),
                        float(request.form["anticipo"]),
                        request.form["metodo_pago"],
                        request.form["referencia"],
                        id_proyecto,
                    ],
                )
        flash(f"Solicitud convertida en proyecto {int(id_proyecto.getvalue())}.", "exito")
    except Exception as error:
        flash(f"No se pudo convertir la solicitud: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/pagos")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def registrar_pago():
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.callproc(
                    "sp_registrar_pago",
                    [
                        int(request.form["id_proyecto"]),
                        float(request.form["monto"]),
                        request.form["tipo_pago"],
                        request.form["metodo_pago"],
                        request.form["referencia"],
                    ],
                )
        flash("Pago registrado.", "exito")
    except Exception as error:
        flash(f"No se pudo registrar el pago: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/cancelar")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def cancelar_evento():
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.callproc(
                    "sp_cancelar_evento",
                    [session["id_usuario"], int(request.form["id_proyecto"]), request.form["motivo"]],
                )
        flash("Evento cancelado.", "exito")
    except Exception as error:
        flash(f"No se pudo cancelar el evento: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/estatus")
@sesion_requerida("GERENTE_ADMIN")
def cambiar_estatus_gerente():
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.callproc(
                    "sp_cambiar_estatus_gerente",
                    [session["id_usuario"], int(request.form["id_gerente"]), request.form["estatus"]],
                )
        flash("Estatus de gerente actualizado.", "exito")
    except Exception as error:
        flash(f"No se pudo actualizar el gerente: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/paquetes")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def crear_paquete_personalizado():
    try:
        platillos = request.form.getlist("platillos")
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_paquete = cursor.var(oracledb.NUMBER)
                cursor.callproc(
                    "sp_crear_paquete_personalizado",
                    [
                        int(request.form["id_cliente"]),
                        request.form["nombre"],
                        request.form["descripcion"],
                        float(request.form["precio_base"]),
                        id_paquete,
                    ],
                )
                for id_platillo in platillos:
                    cursor.callproc("sp_agregar_platillo_paquete", [int(id_paquete.getvalue()), int(id_platillo), 1])
        flash("Paquete personalizado creado.", "exito")
    except Exception as error:
        flash(f"No se pudo crear el paquete: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/platillos")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def crear_platillo():
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_platillo = cursor.var(oracledb.NUMBER)
                cursor.callproc(
                    "sp_alta_platillo",
                    [
                        request.form["nombre"],
                        request.form["descripcion"],
                        float(request.form["precio"]),
                        int(request.form["porciones_base"]),
                        request.form["categoria"],
                        request.form["tipo_dieta"],
                        id_platillo,
                    ],
                )
                nuevo_id = int(id_platillo.getvalue())
                id_ingrediente_var = cursor.var(oracledb.NUMBER)
                cursor.execute(
                    """
                    INSERT INTO INGREDIENTE (id_ingrediente, nombre_ingrediente, unidad_medida, presentacion, observacion)
                    VALUES (sq_ingrediente.NEXTVAL, UPPER(:nombre), :unidad, :presentacion, :observacion)
                    RETURNING id_ingrediente INTO :id_ingrediente
                    """,
                    {
                        "nombre": request.form["ingrediente"],
                        "unidad": request.form["unidad_medida"],
                        "presentacion": request.form.get("presentacion"),
                        "observacion": request.form.get("observacion"),
                        "id_ingrediente": id_ingrediente_var,
                    },
                )
                id_ingrediente = int(id_ingrediente_var.getvalue()[0])
                cursor.execute(
                    """
                    INSERT INTO PLATILLO_INGREDIENTE (folio_pi, id_platillo, id_ingrediente, cantidad)
                    VALUES (sq_platillo_ingrediente.NEXTVAL, :id_platillo, :id_ingrediente, :cantidad)
                    """,
                    {
                        "id_platillo": nuevo_id,
                        "id_ingrediente": id_ingrediente,
                        "cantidad": float(request.form["cantidad"]),
                    },
                )
                cursor.execute(
                    """
                    INSERT INTO INSTRUCCION (id_instruccion, id_platillo, numero_paso, instruccion, detalle_instruccion)
                    VALUES (sq_instruccion.NEXTVAL, :id_platillo, 1, :instruccion, :detalle)
                    """,
                    {
                        "id_platillo": nuevo_id,
                        "instruccion": request.form["instruccion"],
                        "detalle": request.form.get("detalle_instruccion"),
                    },
                )
                conexion.commit()
        flash("Platillo, ingrediente e instruccion registrados.", "exito")
    except Exception as error:
        flash(f"No se pudo crear el platillo: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.route("/gerente/reportes", methods=["GET", "POST"])
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def reportes():
    fecha_inicio = request.values.get("fecha_inicio")
    fecha_fin = request.values.get("fecha_fin")
    parametros = {}
    condicion = ""
    if fecha_inicio and fecha_fin:
        condicion = "WHERE fecha_evento BETWEEN TO_DATE(:fecha_inicio, 'YYYY-MM-DD') AND TO_DATE(:fecha_fin, 'YYYY-MM-DD')"
        parametros = {"fecha_inicio": fecha_inicio, "fecha_fin": fecha_fin}

    ingredientes = consultar(
        f"""
        SELECT nombre_ingrediente, unidad_medida, SUM(cantidad_necesaria) AS cantidad_necesaria
        FROM vw_ingredientes_eventos
        {condicion}
        GROUP BY nombre_ingrediente, unidad_medida
        ORDER BY nombre_ingrediente
        """,
        parametros,
    )
    cobranza = consultar("SELECT * FROM vw_eventos_no_finiquitados_21 ORDER BY fecha_evento")
    popularidad = consultar("SELECT * FROM vw_popularidad_platillos ORDER BY proyectos_demandados DESC, platillo")
    historial = consultar("SELECT * FROM vw_historial_cliente ORDER BY cliente, fecha_evento DESC")
    return render_template(
        "reportes.html",
        ingredientes=ingredientes,
        cobranza=cobranza,
        popularidad=popularidad,
        historial=historial,
        fecha_inicio=fecha_inicio,
        fecha_fin=fecha_fin,
    )


@app.errorhandler(oracledb.Error)
def error_oracle(error):
    return render_template("error.html", mensaje=str(error)), 500


if __name__ == "__main__":
    app.run(
        host=os.getenv("FLASK_HOST", "127.0.0.1"),
        port=int(os.getenv("FLASK_PORT", "5000")),
        debug=True,
        use_reloader=False,
    )
