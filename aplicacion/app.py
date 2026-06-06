from datetime import datetime
import os
import random

import oracledb
from flask import Flask, flash, jsonify, redirect, render_template, request, session, url_for

try:
    from .conexion import abrir_conexion, consultar, registrar_procedimiento
    from .monitor_sql import leer_eventos_sql, limpiar_eventos_sql, registrar_evento_sql
    from .seguridad import generar_hash_contrasena, sesion_requerida, verificar_contrasena
except ImportError:
    from conexion import abrir_conexion, consultar, registrar_procedimiento
    from monitor_sql import leer_eventos_sql, limpiar_eventos_sql, registrar_evento_sql
    from seguridad import generar_hash_contrasena, sesion_requerida, verificar_contrasena


app = Flask(
    __name__,
    template_folder="plantillas",
    static_folder="estatico",
)
app.secret_key = os.getenv("FLASK_SECRET_KEY", "banquetes-catherine-demo")


def separar_nombre_apellido(nombre_completo):
    partes = [parte for parte in nombre_completo.strip().split() if parte]
    if not partes:
        return "Cliente", "Nuevo"
    if len(partes) == 1:
        return partes[0], "Banquetes"
    return " ".join(partes[:-1]), partes[-1]


def valor_float(valor, predeterminado=0):
    try:
        return float(valor)
    except (TypeError, ValueError):
        return predeterminado


def numero_desde_var(variable):
    valor = variable.getvalue()
    if isinstance(valor, list):
        valor = valor[0]
    return int(valor)


def cargar_opciones_solicitud():
    datos = {
        "salones": [],
        "paquetes": [],
        "error_bd": None,
    }
    try:
        datos["salones"] = consultar(
            "SELECT id_salon, nombre, capacidad_maxima, costo_renta FROM vw_salones_publicos ORDER BY capacidad_maxima",
            accion="Agenda modal: opciones salones",
        )
        datos["paquetes"] = consultar(
            """
            SELECT id_paquete, nombre, precio_base, complementos_persona, complementos_evento
            FROM vw_paquete_resumen
            WHERE visible_publico = 'S'
              AND personalizado = 'N'
            ORDER BY precio_base
            """,
            accion="Agenda modal: opciones paquetes",
        )
        for salon in datos["salones"]:
            salon["id_salon"] = int(salon["id_salon"])
            salon["capacidad_maxima"] = int(salon["capacidad_maxima"])
            salon["costo_renta"] = valor_float(salon.get("costo_renta"), 0)
        for paquete in datos["paquetes"]:
            paquete["id_paquete"] = int(paquete["id_paquete"])
            paquete["precio_base"] = valor_float(paquete.get("precio_base"), 0)
            paquete["complementos_persona"] = valor_float(paquete.get("complementos_persona"), 0)
            paquete["complementos_evento"] = valor_float(paquete.get("complementos_evento"), 0)
    except Exception as error:
        datos["error_bd"] = str(error)
    return datos


@app.route("/")
def inicio():
    return render_template("inicio.html")


@app.get("/platillos")
def platillos_publicos():
    platillos = consultar("SELECT * FROM vw_platillos_publicos ORDER BY categoria, nombre", accion="Catalogo publico: platillos")
    return render_template("platillos.html", platillos=platillos)


@app.get("/complementos")
def complementos_publicos():
    complementos = consultar("SELECT * FROM vw_complementos_publicos ORDER BY nombre", accion="Catalogo publico: complementos")
    return render_template("complementos.html", complementos=complementos)


@app.get("/salones")
def salones_publicos():
    salones = consultar("SELECT * FROM vw_salones_publicos ORDER BY capacidad_maxima", accion="Catalogo publico: salones")
    return render_template("salones.html", salones=salones)


@app.get("/api/opciones-solicitud")
def api_opciones_solicitud():
    return jsonify(cargar_opciones_solicitud())


@app.get("/api/cotizacion")
def api_cotizacion():
    try:
        numero_invitados = int(request.args.get("numero_invitados") or 0)
        id_salon = int(request.args.get("id_salon") or 0)
        id_paquete = int(request.args.get("id_paquete") or 0)
        if numero_invitados <= 0 or id_salon <= 0 or id_paquete <= 0:
            return jsonify({"total_estimado": None, "costo_por_persona": None})

        filas = consultar(
            """
            SELECT
                fn_total_estimado_evento(:numero_invitados, :id_salon, :id_paquete) AS total_estimado,
                fn_costo_paquete_persona(:id_paquete) AS costo_por_persona
            FROM dual
            """,
            {
                "numero_invitados": numero_invitados,
                "id_salon": id_salon,
                "id_paquete": id_paquete,
            },
            accion="Cotizacion: calcular total por persona",
        )
        if not filas:
            return jsonify({"total_estimado": None, "costo_por_persona": None})
        return jsonify({
            "total_estimado": valor_float(filas[0].get("total_estimado"), None),
            "costo_por_persona": valor_float(filas[0].get("costo_por_persona"), None),
        })
    except Exception as error:
        return jsonify({"error": str(error)}), 400


@app.get("/consola-sql")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def consola_sql():
    return render_template("consola_sql.html", eventos=leer_eventos_sql())


@app.get("/api/consola-sql")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def api_consola_sql():
    return jsonify(leer_eventos_sql())


@app.post("/consola-sql/limpiar")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def limpiar_consola_sql():
    limpiar_eventos_sql()
    registrar_evento_sql(
        accion="Consola SQL limpiada",
        sentencia="-- Se limpio el monitor SQL de la demo",
        resultado="Monitor reiniciado",
        tipo="SISTEMA",
    )
    return redirect(url_for("consola_sql"))


@app.post("/solicitudes")
def crear_solicitud():
    try:
        fecha_evento = datetime.strptime(request.form["fecha_evento"], "%Y-%m-%d")
        correo = request.form["correo"].strip().lower()
        contrasena_temporal = str(random.randint(100000, 999999))
        credenciales_nuevas = False
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_solicitud = cursor.var(oracledb.NUMBER)
                parametros = [
                    request.form["nombre_contacto"],
                    correo,
                    request.form.get("telefono"),
                    fecha_evento,
                    int(request.form["numero_invitados"]),
                    int(request.form["id_salon_preferido"]) if request.form.get("id_salon_preferido") else None,
                    int(request.form["id_paquete_preferido"]) if request.form.get("id_paquete_preferido") else None,
                    request.form.get("mensaje"),
                    id_solicitud,
                ]
                cursor.callproc(
                    "sp_crear_solicitud",
                    parametros,
                )
                nuevo_id_solicitud = numero_desde_var(id_solicitud)
                registrar_procedimiento("Solicitud publica: crear solicitud", "sp_crear_solicitud", parametros, f"Solicitud {nuevo_id_solicitud}; COMMIT")

                cursor.execute("SELECT id_cliente FROM CLIENTE WHERE LOWER(correo) = :correo", {"correo": correo})
                cliente_existente = cursor.fetchone()
                if not cliente_existente:
                    nombre, apellido = separar_nombre_apellido(request.form["nombre_contacto"])
                    id_usuario = cursor.var(oracledb.NUMBER)
                    sql_usuario = """
                        INSERT INTO USUARIO (id_usuario, nombre_usuario, hash_contrasena, rol)
                        VALUES (sq_usuario.NEXTVAL, :correo, :hash_contrasena, 'CLIENTE')
                        RETURNING id_usuario INTO :id_usuario
                    """
                    parametros_usuario = {
                        "correo": correo,
                        "hash_contrasena": generar_hash_contrasena(contrasena_temporal),
                        "id_usuario": id_usuario,
                    }
                    cursor.execute(sql_usuario, parametros_usuario)
                    nuevo_id_usuario = numero_desde_var(id_usuario)
                    registrar_evento_sql(
                        "Solicitud publica: crear usuario cliente",
                        sql_usuario,
                        {"correo": correo, "hash_contrasena": "***"},
                        filas=1,
                        resultado=f"Usuario {nuevo_id_usuario} creado",
                    )

                    id_cliente = cursor.var(oracledb.NUMBER)
                    sql_cliente = """
                        INSERT INTO CLIENTE (id_cliente, id_usuario, nombre, apellido, correo, telefono, direccion)
                        VALUES (sq_cliente.NEXTVAL, :id_usuario, INITCAP(:nombre), INITCAP(:apellido), :correo, :telefono, 'Capturada desde portal publico')
                        RETURNING id_cliente INTO :id_cliente
                    """
                    parametros_cliente = {
                        "id_usuario": nuevo_id_usuario,
                        "nombre": nombre,
                        "apellido": apellido,
                        "correo": correo,
                        "telefono": request.form.get("telefono"),
                        "id_cliente": id_cliente,
                    }
                    cursor.execute(sql_cliente, parametros_cliente)
                    conexion.commit()
                    registrar_evento_sql(
                        "Solicitud publica: crear cliente",
                        sql_cliente,
                        parametros_cliente,
                        filas=1,
                        resultado=f"Cliente {numero_desde_var(id_cliente)} creado; COMMIT",
                    )
                    credenciales_nuevas = True
        flash(f"Solicitud registrada con folio SOL-{nuevo_id_solicitud:05d}.", "exito")
        if credenciales_nuevas:
            flash(f"Acceso cliente creado. Usuario: {correo} | Contrasena temporal: {contrasena_temporal}", "credenciales")
        else:
            flash(f"Ya existe una cuenta cliente para {correo}. Puedes entrar con tus credenciales.", "aviso")
    except Exception as error:
        registrar_procedimiento("Solicitud publica: crear solicitud", "sp_crear_solicitud", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo registrar la solicitud: {error}", "error")
    return redirect(request.referrer or url_for("inicio"))


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
        accion="Login: buscar usuario activo",
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
    if usuario["rol"] == "CHEF":
        return redirect(url_for("panel_chef"))
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
        accion="Panel cliente: proyectos activos",
    )
    paquetes = consultar(
        """
        SELECT id_paquete, nombre, descripcion, precio_base, visible_publico, personalizado,
               platillos, complementos, complementos_persona, complementos_evento
        FROM vw_paquete_resumen
        WHERE (
                visible_publico = 'S'
                OR id_cliente = (SELECT id_cliente FROM CLIENTE WHERE id_usuario = :id_usuario)
              )
        ORDER BY personalizado DESC, nombre
        """,
        {"id_usuario": session["id_usuario"]},
        accion="Panel cliente: paquetes visibles",
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
        accion="Panel cliente: notificaciones",
    )
    solicitudes = consultar(
        """
        SELECT ss.*, 'SOL-' || LPAD(ss.id_solicitud, 5, '0') AS folio_solicitud,
               NVL(s.nombre, 'Sin preferencia') AS salon_preferido,
               NVL(p.nombre, 'Sin preferencia') AS paquete_preferido
        FROM SOLICITUD_SERVICIO ss
        LEFT JOIN SALON s ON s.id_salon = ss.id_salon_preferido
        LEFT JOIN PAQUETE p ON p.id_paquete = ss.id_paquete_preferido
        WHERE ss.correo = (SELECT correo FROM CLIENTE WHERE id_usuario = :id_usuario)
        ORDER BY ss.fecha_solicitud DESC
        """,
        {"id_usuario": session["id_usuario"]},
        accion="Panel cliente: solicitudes propias",
    )
    invitados = consultar(
        """
        SELECT inv.*
        FROM vw_invitados_proyecto inv
        INNER JOIN CLIENTE c ON c.id_cliente = inv.id_cliente
        WHERE c.id_usuario = :id_usuario
        ORDER BY inv.id_proyecto, inv.nombre
        """,
        {"id_usuario": session["id_usuario"]},
        accion="Panel cliente: invitados por proyecto",
    )
    cortesias = consultar(
        """
        SELECT *
        FROM vw_cortesias_cliente
        WHERE id_cliente = (SELECT id_cliente FROM CLIENTE WHERE id_usuario = :id_usuario)
        ORDER BY id_proyecto, tipo_cortesia, fecha_registro DESC
        """,
        {"id_usuario": session["id_usuario"]},
        accion="Panel cliente: cortesias de prueba",
    )
    opciones = cargar_opciones_solicitud()
    return render_template(
        "cliente.html",
        proyectos=proyectos,
        paquetes=paquetes,
        notificaciones=notificaciones,
        solicitudes=solicitudes,
        invitados=invitados,
        cortesias=cortesias,
        opciones=opciones,
    )


@app.post("/cliente/proyectos/<int:id_proyecto>/invitados")
@sesion_requerida("CLIENTE")
def actualizar_invitados(id_proyecto):
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                parametros = [session["id_usuario"], id_proyecto, int(request.form["numero_invitados"])]
                cursor.callproc("sp_actualizar_invitados", parametros)
                registrar_procedimiento("Cliente: actualizar invitados", "sp_actualizar_invitados", parametros, "Invitados actualizados; COMMIT")
        flash("Numero de invitados actualizado.", "exito")
    except Exception as error:
        registrar_procedimiento("Cliente: actualizar invitados", "sp_actualizar_invitados", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo actualizar invitados: {error}", "error")
    return redirect(url_for("panel_cliente"))


@app.post("/cliente/solicitudes/<int:id_solicitud>/actualizar")
@sesion_requerida("CLIENTE")
def actualizar_solicitud_cliente(id_solicitud):
    sql = """
        UPDATE SOLICITUD_SERVICIO
        SET fecha_evento = TO_DATE(:fecha_evento, 'YYYY-MM-DD'),
            numero_invitados = :numero_invitados,
            id_salon_preferido = :id_salon_preferido,
            id_paquete_preferido = :id_paquete_preferido,
            mensaje = :mensaje,
            observaciones = 'Actualizada por el cliente desde el portal'
        WHERE id_solicitud = :id_solicitud
          AND estatus = 'PENDIENTE'
          AND correo = (SELECT correo FROM CLIENTE WHERE id_usuario = :id_usuario)
    """
    parametros = {
        "fecha_evento": request.form["fecha_evento"],
        "numero_invitados": int(request.form["numero_invitados"]),
        "id_salon_preferido": int(request.form["id_salon_preferido"]) if request.form.get("id_salon_preferido") else None,
        "id_paquete_preferido": int(request.form["id_paquete_preferido"]) if request.form.get("id_paquete_preferido") else None,
        "mensaje": request.form.get("mensaje"),
        "id_solicitud": id_solicitud,
        "id_usuario": session["id_usuario"],
    }
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(sql, parametros)
                filas = cursor.rowcount
                if filas == 0:
                    raise ValueError("Solo se pueden modificar solicitudes pendientes propias.")
                conexion.commit()
                registrar_evento_sql("Cliente: actualizar solicitud pendiente", sql, parametros, filas=filas, resultado="Solicitud actualizada; COMMIT")
        flash("Solicitud actualizada.", "exito")
    except Exception as error:
        registrar_evento_sql("Cliente: actualizar solicitud pendiente", sql, parametros, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo actualizar la solicitud: {error}", "error")
    return redirect(url_for("panel_cliente"))


@app.post("/cliente/proyectos/<int:id_proyecto>/invitados-evento")
@sesion_requerida("CLIENTE")
def registrar_invitado_evento(id_proyecto):
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_invitado = cursor.var(oracledb.NUMBER)
                parametros = [
                    session["id_usuario"],
                    id_proyecto,
                    request.form["nombre"],
                    request.form.get("correo"),
                    request.form.get("telefono"),
                    id_invitado,
                ]
                cursor.callproc("sp_registrar_invitado", parametros)
                registrar_procedimiento("Cliente: agregar invitado a lista", "sp_registrar_invitado", parametros, f"Invitado {numero_desde_var(id_invitado)}; notificacion; COMMIT")
        flash("Invitado agregado a la lista.", "exito")
    except Exception as error:
        registrar_procedimiento("Cliente: agregar invitado a lista", "sp_registrar_invitado", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo registrar invitado: {error}", "error")
    return redirect(url_for("panel_cliente"))


@app.post("/cliente/proyectos/<int:id_proyecto>/cortesias")
@sesion_requerida("CLIENTE")
def registrar_cortesia_cliente(id_proyecto):
    sql_validar = """
        SELECT pe.id_proyecto
        FROM PROYECTO_EVENTO pe
        INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
        WHERE pe.id_proyecto = :id_proyecto
          AND c.id_usuario = :id_usuario
          AND pe.estatus = 'ACTIVO'
    """
    sql = """
        INSERT INTO CORTESIA_EVENTO (id_cortesia, id_proyecto, tipo_cortesia, titulo, detalle, estatus)
        VALUES (sq_cortesia.NEXTVAL, :id_proyecto, :tipo_cortesia, :titulo, :detalle, 'PENDIENTE')
    """
    parametros = {
        "id_proyecto": id_proyecto,
        "tipo_cortesia": request.form["tipo_cortesia"],
        "titulo": request.form["titulo"],
        "detalle": request.form.get("detalle"),
    }
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(sql_validar, {"id_proyecto": id_proyecto, "id_usuario": session["id_usuario"]})
                if not cursor.fetchone():
                    raise ValueError("Proyecto no disponible para este cliente.")
                registrar_evento_sql(
                    "Cliente: validar proyecto para cortesia",
                    sql_validar,
                    {"id_proyecto": id_proyecto, "id_usuario": session["id_usuario"]},
                    filas=1,
                    resultado="Proyecto activo validado",
                )
                cursor.execute(sql, parametros)
                conexion.commit()
                registrar_evento_sql("Cliente: registrar cortesia de prueba", sql, parametros, filas=cursor.rowcount, resultado="Cortesia registrada; COMMIT")
        flash("Funcion de prueba guardada para tu evento.", "exito")
    except Exception as error:
        registrar_evento_sql("Cliente: registrar cortesia de prueba", sql, parametros, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo guardar la funcion de prueba: {error}", "error")
    return redirect(url_for("panel_cliente"))


@app.post("/cliente/invitados/<int:id_invitado>/confirmar")
@sesion_requerida("CLIENTE")
def confirmar_invitado_evento(id_invitado):
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                parametros = [session["id_usuario"], id_invitado, request.form["estatus_confirmacion"]]
                cursor.callproc("sp_confirmar_invitado", parametros)
                registrar_procedimiento("Cliente: confirmar invitado", "sp_confirmar_invitado", parametros, "Confirmacion actualizada; COMMIT")
        flash("Confirmacion de invitado actualizada.", "exito")
    except Exception as error:
        registrar_procedimiento("Cliente: confirmar invitado", "sp_confirmar_invitado", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo confirmar invitado: {error}", "error")
    return redirect(url_for("panel_cliente"))


@app.get("/gerente")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def panel_gerente():
    solicitudes = consultar("SELECT * FROM vw_solicitudes_pendientes ORDER BY fecha_solicitud", accion="Panel gerente: solicitudes pendientes")
    solicitudes_todas = consultar(
        """
        SELECT ss.id_solicitud, ss.nombre_contacto, ss.correo, ss.fecha_evento, ss.numero_invitados,
               ss.estatus, ss.mensaje, ss.observaciones, ss.id_salon_preferido, ss.id_paquete_preferido
        FROM SOLICITUD_SERVICIO ss
        ORDER BY ss.fecha_solicitud DESC
        """,
        accion="Panel gerente: solicitudes para modificar",
    )
    proyectos = consultar(
        """
        SELECT pe.id_proyecto, ep.folio_proyecto, pe.nombre_evento, pe.fecha_evento,
               pe.numero_invitados, pe.id_salon, pe.id_paquete,
               c.nombre || ' ' || c.apellido AS cliente, s.nombre AS salon,
               p.nombre AS paquete,
               ep.total_estimado, ep.total_pagado, ep.saldo_pendiente,
               ROUND(ep.total_estimado / NULLIF(pe.numero_invitados, 0), 2) AS costo_por_persona,
               pe.estatus, pe.finiquitado
        FROM PROYECTO_EVENTO pe
        INNER JOIN CLIENTE c ON c.id_cliente = pe.id_cliente
        INNER JOIN SALON s ON s.id_salon = pe.id_salon
        INNER JOIN PAQUETE p ON p.id_paquete = pe.id_paquete
        INNER JOIN vw_estado_pago_proyecto ep ON ep.id_proyecto = pe.id_proyecto
        WHERE pe.estatus = 'ACTIVO'
        ORDER BY pe.fecha_evento
        """,
        accion="Panel gerente: proyectos activos",
    )
    clientes = consultar("SELECT id_cliente, nombre || ' ' || apellido AS cliente FROM CLIENTE ORDER BY cliente", accion="Panel gerente: catalogo clientes")
    gerentes = consultar("SELECT id_gerente, nombre, estatus FROM GERENTE ORDER BY nombre", accion="Panel gerente: catalogo gerentes")
    salones = consultar("SELECT id_salon, nombre, capacidad_maxima, costo_renta FROM SALON WHERE activo = 'S' ORDER BY capacidad_maxima", accion="Panel gerente: catalogo salones")
    paquetes = consultar("SELECT * FROM vw_paquete_resumen ORDER BY personalizado DESC, nombre", accion="Panel gerente: catalogo paquetes")
    platillos = consultar("SELECT id_platillo, nombre, precio, costo_estimado FROM PLATILLO WHERE activo = 'S' ORDER BY nombre", accion="Panel gerente: catalogo platillos")
    complementos = consultar("SELECT id_complemento, nombre, precio, tipo_complemento, tipo_cobro FROM COMPLEMENTO WHERE activo = 'S' ORDER BY tipo_complemento, nombre", accion="Panel gerente: catalogo complementos")
    return render_template(
        "gerente.html",
        solicitudes=solicitudes,
        solicitudes_todas=solicitudes_todas,
        proyectos=proyectos,
        clientes=clientes,
        gerentes=gerentes,
        salones=salones,
        paquetes=paquetes,
        platillos=platillos,
        complementos=complementos,
    )


@app.post("/gerente/solicitudes/<int:id_solicitud>/convertir")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def convertir_solicitud(id_solicitud):
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_proyecto = cursor.var(oracledb.NUMBER)
                parametros = [
                    id_solicitud,
                    int(request.form["id_cliente"]),
                    int(request.form["id_gerente"]),
                    int(request.form["id_salon"]),
                    int(request.form["id_paquete"]),
                    request.form["nombre_evento"],
                    0,
                    float(request.form["anticipo"]),
                    request.form["metodo_pago"],
                    request.form["referencia"],
                    id_proyecto,
                ]
                cursor.callproc(
                    "sp_crear_proyecto_desde_solicitud",
                    parametros,
                )
                nuevo_id = numero_desde_var(id_proyecto)
                registrar_procedimiento("Gerente: convertir solicitud en proyecto", "sp_crear_proyecto_desde_solicitud", parametros, f"Proyecto {nuevo_id}; anticipo registrado; COMMIT")
        flash(f"Solicitud convertida en proyecto BC-{nuevo_id:05d}.", "exito")
    except Exception as error:
        registrar_procedimiento("Gerente: convertir solicitud en proyecto", "sp_crear_proyecto_desde_solicitud", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo convertir la solicitud: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/solicitudes/<int:id_solicitud>/actualizar")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def actualizar_solicitud_gerente(id_solicitud):
    sql = """
        UPDATE SOLICITUD_SERVICIO
        SET fecha_evento = TO_DATE(:fecha_evento, 'YYYY-MM-DD'),
            numero_invitados = :numero_invitados,
            id_salon_preferido = :id_salon_preferido,
            id_paquete_preferido = :id_paquete_preferido,
            estatus = :estatus,
            observaciones = :observaciones
        WHERE id_solicitud = :id_solicitud
    """
    parametros = {
        "fecha_evento": request.form["fecha_evento"],
        "numero_invitados": int(request.form["numero_invitados"]),
        "id_salon_preferido": int(request.form["id_salon_preferido"]) if request.form.get("id_salon_preferido") else None,
        "id_paquete_preferido": int(request.form["id_paquete_preferido"]) if request.form.get("id_paquete_preferido") else None,
        "estatus": request.form["estatus"],
        "observaciones": request.form.get("observaciones"),
        "id_solicitud": id_solicitud,
    }
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(sql, parametros)
                conexion.commit()
                registrar_evento_sql("Gerente: modificar solicitud propuesta", sql, parametros, filas=cursor.rowcount, resultado="Solicitud modificada; COMMIT")
        flash("Solicitud modificada por gerencia.", "exito")
    except Exception as error:
        registrar_evento_sql("Gerente: modificar solicitud propuesta", sql, parametros, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo modificar la solicitud: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/pagos")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def registrar_pago():
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                parametros = [
                    int(request.form["id_proyecto"]),
                    float(request.form["monto"]),
                    request.form["tipo_pago"],
                    request.form["metodo_pago"],
                    request.form["referencia"],
                ]
                cursor.callproc("sp_registrar_pago", parametros)
                registrar_procedimiento("Gerente: registrar pago", "sp_registrar_pago", parametros, "Pago registrado; posible finiquito; COMMIT")
        flash("Pago registrado.", "exito")
    except Exception as error:
        registrar_procedimiento("Gerente: registrar pago", "sp_registrar_pago", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo registrar el pago: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/proyectos/<int:id_proyecto>/actualizar")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def actualizar_proyecto_gerente(id_proyecto):
    sql_capacidad = """
        SELECT capacidad_maxima, convenio_activo, activo
        FROM SALON
        WHERE id_salon = :id_salon
    """
    sql = """
        UPDATE PROYECTO_EVENTO
        SET fecha_evento = TO_DATE(:fecha_evento, 'YYYY-MM-DD'),
            numero_invitados = :numero_invitados,
            id_salon = :id_salon,
            id_paquete = :id_paquete,
            total_estimado = fn_total_estimado_evento(:numero_invitados, :id_salon, :id_paquete),
            finiquitado = CASE
                WHEN fn_total_pagado(:id_proyecto) >= fn_total_estimado_evento(:numero_invitados, :id_salon, :id_paquete) THEN 'S'
                ELSE 'N'
            END,
            fecha_actualizacion = SYSDATE
        WHERE id_proyecto = :id_proyecto
          AND estatus = 'ACTIVO'
    """
    parametros = {
        "id_proyecto": id_proyecto,
        "fecha_evento": request.form["fecha_evento"],
        "numero_invitados": int(request.form["numero_invitados"]),
        "id_salon": int(request.form["id_salon"]),
        "id_paquete": int(request.form["id_paquete"]),
    }
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(sql_capacidad, {"id_salon": parametros["id_salon"]})
                capacidad = cursor.fetchone()
                if not capacidad:
                    raise ValueError("Salon no encontrado.")
                capacidad_maxima, convenio_activo, salon_activo = capacidad
                registrar_evento_sql(
                    "Gerente: validar capacidad para modificar proyecto",
                    sql_capacidad,
                    {"id_salon": parametros["id_salon"]},
                    filas=1,
                    resultado=f"Capacidad {capacidad_maxima}",
                    muestra=[{"capacidad_maxima": capacidad_maxima, "convenio_activo": convenio_activo, "activo": salon_activo}],
                )
                if salon_activo != "S" or convenio_activo != "S":
                    raise ValueError("El salon no tiene convenio activo.")
                if parametros["numero_invitados"] > capacidad_maxima:
                    cursor.execute("SELECT fn_salones_sugeridos(:invitados) FROM dual", {"invitados": parametros["numero_invitados"]})
                    sugerencias = cursor.fetchone()[0]
                    raise ValueError(f"El salon no tiene capacidad. Alternativas: {sugerencias}")

                cursor.execute(
                    """
                    SELECT id_cliente, id_salon
                    FROM PROYECTO_EVENTO
                    WHERE id_proyecto = :id_proyecto
                      AND estatus = 'ACTIVO'
                    FOR UPDATE
                    """,
                    {"id_proyecto": id_proyecto},
                )
                proyecto_actual = cursor.fetchone()
                if not proyecto_actual:
                    raise ValueError("Proyecto activo no encontrado.")
                id_cliente, salon_anterior = proyecto_actual
                cursor.execute(sql, parametros)
                if cursor.rowcount == 0:
                    raise ValueError("No se actualizo el proyecto.")
                cursor.callproc(
                    "sp_insertar_notificacion",
                    [
                        "CLIENTE",
                        id_cliente,
                        id_proyecto,
                        None,
                        "WEB",
                        "Proyecto actualizado",
                        "Gerencia actualizo fecha, salon, paquete o invitados. El total se recalculo automaticamente.",
                    ],
                )
                if salon_anterior != parametros["id_salon"]:
                    cursor.callproc(
                        "sp_insertar_notificacion",
                        [
                            "INSTALACION",
                            None,
                            id_proyecto,
                            parametros["id_salon"],
                            "CORREO",
                            "Cambio relevante para instalacion",
                            "Gerencia cambio salon o montaje del proyecto.",
                        ],
                    )
                conexion.commit()
                registrar_evento_sql("Gerente: modificar proyecto activo", sql, parametros, filas=cursor.rowcount, resultado="Proyecto actualizado; notificaciones; COMMIT")
        flash("Proyecto actualizado y costo recalculado.", "exito")
    except Exception as error:
        registrar_evento_sql("Gerente: modificar proyecto activo", sql, parametros, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo modificar el proyecto: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/cancelar")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def cancelar_evento():
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                parametros = [session["id_usuario"], int(request.form["id_proyecto"]), request.form["motivo"]]
                cursor.callproc("sp_cancelar_evento", parametros)
                registrar_procedimiento("Gerente: cancelar evento", "sp_cancelar_evento", parametros, "Evento cancelado; notificaciones creadas; COMMIT")
        flash("Evento cancelado.", "exito")
    except Exception as error:
        registrar_procedimiento("Gerente: cancelar evento", "sp_cancelar_evento", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo cancelar el evento: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/estatus")
@sesion_requerida("GERENTE_ADMIN")
def cambiar_estatus_gerente():
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                parametros = [session["id_usuario"], int(request.form["id_gerente"]), request.form["estatus"]]
                cursor.callproc("sp_cambiar_estatus_gerente", parametros)
                registrar_procedimiento("Gerente admin: cambiar estatus gerente", "sp_cambiar_estatus_gerente", parametros, "Estatus actualizado; COMMIT")
        flash("Estatus de gerente actualizado.", "exito")
    except Exception as error:
        registrar_procedimiento("Gerente admin: cambiar estatus gerente", "sp_cambiar_estatus_gerente", resultado="Error; ROLLBACK", error=error)
        flash(f"No se pudo actualizar el gerente: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/gerente/paquetes")
@sesion_requerida("GERENTE", "GERENTE_ADMIN")
def crear_paquete_personalizado():
    sql_paquete = """
        INSERT INTO PAQUETE (
            id_paquete, nombre, descripcion, precio_base, tipo_paquete,
            margen_ganancia, visible_publico, personalizado, id_cliente
        ) VALUES (
            sq_paquete.NEXTVAL, INITCAP(:nombre), :descripcion, :precio_base,
            :tipo_paquete, :margen_ganancia, 'N', 'S', :id_cliente
        )
        RETURNING id_paquete INTO :id_paquete
    """
    try:
        platillos = request.form.getlist("platillos")
        complementos = request.form.getlist("complementos")
        if not platillos:
            raise ValueError("Selecciona al menos un platillo para armar el menu.")
        margen = valor_float(request.form.get("margen_ganancia"), 35)
        precio_manual = valor_float(request.form.get("precio_base"), 0)
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                costo_base = 0
                for id_platillo in platillos:
                    cursor.execute("SELECT costo_estimado FROM PLATILLO WHERE id_platillo = :id_platillo AND activo = 'S'", {"id_platillo": int(id_platillo)})
                    fila = cursor.fetchone()
                    if fila:
                        costo_base += float(fila[0] or 0)
                for id_complemento in complementos:
                    cursor.execute(
                        """
                        SELECT CASE WHEN tipo_cobro = 'POR_PERSONA' THEN precio ELSE 0 END
                        FROM COMPLEMENTO
                        WHERE id_complemento = :id_complemento
                          AND activo = 'S'
                        """,
                        {"id_complemento": int(id_complemento)},
                    )
                    fila = cursor.fetchone()
                    if fila:
                        costo_base += float(fila[0] or 0)
                precio_base = precio_manual if precio_manual > 0 else round(costo_base * (1 + margen / 100), 2)
                id_paquete = cursor.var(oracledb.NUMBER)
                parametros_paquete = {
                    "id_cliente": int(request.form["id_cliente"]),
                    "nombre": request.form["nombre"],
                    "descripcion": request.form.get("descripcion"),
                    "precio_base": precio_base,
                    "tipo_paquete": request.form.get("tipo_paquete") or "PERSONALIZADO",
                    "margen_ganancia": margen,
                    "id_paquete": id_paquete,
                }
                cursor.execute(sql_paquete, parametros_paquete)
                nuevo_id_paquete = numero_desde_var(id_paquete)
                registrar_evento_sql(
                    "Gerente: crear menu personalizado",
                    sql_paquete,
                    {**parametros_paquete, "id_paquete": "OUT"},
                    filas=1,
                    resultado=f"Paquete {nuevo_id_paquete} privado",
                    tipo="TRANSACCION",
                )
                for id_platillo in platillos:
                    sql_platillo = """
                        INSERT INTO PAQUETE_PLATILLO (id_paquete_platillo, id_paquete, id_platillo, cantidad)
                        VALUES (sq_paquete_platillo.NEXTVAL, :id_paquete, :id_platillo, 1)
                    """
                    parametros_platillo = {"id_paquete": nuevo_id_paquete, "id_platillo": int(id_platillo)}
                    cursor.execute(sql_platillo, parametros_platillo)
                    registrar_evento_sql("Gerente: relacionar platillo con menu", sql_platillo, parametros_platillo, filas=1, resultado="Platillo agregado")
                for id_complemento in complementos:
                    sql_complemento = """
                        INSERT INTO PAQUETE_COMPLEMENTO (id_paquete_complemento, id_paquete, id_complemento, cantidad)
                        VALUES (sq_paquete_complemento.NEXTVAL, :id_paquete, :id_complemento, 1)
                    """
                    parametros_complemento = {"id_paquete": nuevo_id_paquete, "id_complemento": int(id_complemento)}
                    cursor.execute(sql_complemento, parametros_complemento)
                    registrar_evento_sql("Gerente: relacionar complemento con menu", sql_complemento, parametros_complemento, filas=1, resultado="Complemento agregado")
                conexion.commit()
        flash(f"Menu personalizado creado con costo por persona de ${precio_base:.2f}.", "exito")
    except Exception as error:
        registrar_evento_sql("Gerente: crear menu personalizado", sql_paquete, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo crear el paquete: {error}", "error")
    return redirect(url_for("panel_gerente"))


@app.post("/chef/platillos")
@sesion_requerida("CHEF")
def crear_platillo():
    sql_platillo = """
        INSERT INTO PLATILLO (
            id_platillo, nombre, descripcion, precio, costo_estimado,
            porciones_base, categoria, tipo_dieta, dificultad, foto_url
        ) VALUES (
            sq_platillo.NEXTVAL, UPPER(TRIM(:nombre)), :descripcion, :precio,
            :costo_estimado, :porciones_base, UPPER(TRIM(:categoria)),
            UPPER(TRIM(:tipo_dieta)), UPPER(TRIM(:dificultad)), :foto_url
        )
        RETURNING id_platillo INTO :id_platillo
    """
    try:
        costo_estimado = valor_float(request.form.get("costo_estimado"), 0)
        margen = valor_float(request.form.get("margen_ganancia"), 35)
        precio = valor_float(request.form.get("precio"), 0)
        if precio <= 0:
            precio = round(costo_estimado * (1 + margen / 100), 2)
        ingredientes_receta = request.form.getlist("ingredientes_receta")
        cantidades_receta = request.form.getlist("cantidades_receta")
        pasos_receta = [paso.strip() for paso in request.form.getlist("pasos_receta") if paso.strip()]
        if not ingredientes_receta:
            raise ValueError("Agrega al menos un ingrediente existente a la receta.")
        if not pasos_receta:
            raise ValueError("Agrega al menos un procedimiento.")

        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                id_platillo = cursor.var(oracledb.NUMBER)
                parametros_platillo = [
                    request.form["nombre"],
                    request.form["descripcion"],
                    precio,
                    costo_estimado,
                    int(request.form["porciones_base"]),
                    request.form["categoria"],
                    request.form["tipo_dieta"],
                    request.form.get("dificultad") or "MEDIA",
                    id_platillo,
                ]
                parametros_insert = {
                    "nombre": parametros_platillo[0],
                    "descripcion": parametros_platillo[1],
                    "precio": parametros_platillo[2],
                    "costo_estimado": parametros_platillo[3],
                    "porciones_base": parametros_platillo[4],
                    "categoria": parametros_platillo[5],
                    "tipo_dieta": parametros_platillo[6] or "GENERAL",
                    "dificultad": parametros_platillo[7],
                    "foto_url": request.form.get("foto_url") or "img/hero-banquetes.png",
                    "id_platillo": id_platillo,
                }
                cursor.execute(sql_platillo, parametros_insert)
                nuevo_id = numero_desde_var(id_platillo)
                registrar_evento_sql(
                    "Cocina: alta de receta presupuestada",
                    sql_platillo,
                    {**parametros_insert, "id_platillo": "OUT", "margen_ganancia": margen},
                    filas=1,
                    resultado=f"Platillo {nuevo_id}; precio calculado ${precio:.2f}",
                    tipo="TRANSACCION",
                )

                sql_relacion = """
                    INSERT INTO PLATILLO_INGREDIENTE (folio_pi, id_platillo, id_ingrediente, cantidad)
                    VALUES (sq_platillo_ingrediente.NEXTVAL, :id_platillo, :id_ingrediente, :cantidad)
                """
                for indice, id_ingrediente in enumerate(ingredientes_receta):
                    cantidad = valor_float(cantidades_receta[indice] if indice < len(cantidades_receta) else 0, 0)
                    if cantidad <= 0:
                        raise ValueError("Cada ingrediente debe tener cantidad mayor a cero.")
                    parametros_relacion = {"id_platillo": nuevo_id, "id_ingrediente": int(id_ingrediente), "cantidad": cantidad}
                    cursor.execute(sql_relacion, parametros_relacion)
                    registrar_evento_sql("Cocina: relacionar ingrediente de receta", sql_relacion, parametros_relacion, filas=1, resultado="Ingrediente relacionado")

                sql_instruccion = """
                    INSERT INTO INSTRUCCION (id_instruccion, id_platillo, numero_paso, instruccion, detalle_instruccion)
                    VALUES (sq_instruccion.NEXTVAL, :id_platillo, :numero_paso, :instruccion, :detalle)
                """
                detalles_paso = request.form.getlist("detalles_paso")
                for numero_paso, paso in enumerate(pasos_receta, start=1):
                    parametros_instruccion = {
                        "id_platillo": nuevo_id,
                        "numero_paso": numero_paso,
                        "instruccion": paso,
                        "detalle": detalles_paso[numero_paso - 1] if numero_paso - 1 < len(detalles_paso) else None,
                    }
                    cursor.execute(sql_instruccion, parametros_instruccion)
                    registrar_evento_sql("Cocina: insertar procedimiento de receta", sql_instruccion, parametros_instruccion, filas=1, resultado="Paso insertado")
                conexion.commit()
        flash("Receta registrada con presupuesto, ingredientes y procedimientos.", "exito")
    except Exception as error:
        registrar_evento_sql("Cocina: alta de receta completa", sql_platillo, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo crear el platillo: {error}", "error")
    return redirect(url_for("panel_chef"))


@app.get("/chef")
@sesion_requerida("CHEF")
def panel_chef():
    platillos = consultar(
        """
        SELECT id_platillo, nombre, descripcion, precio, costo_estimado,
               porciones_base, categoria, tipo_dieta, dificultad, foto_url
        FROM PLATILLO
        WHERE activo = 'S'
        ORDER BY categoria, nombre
        """,
        accion="Panel chef: platillos",
    )
    ingredientes = consultar(
        "SELECT id_ingrediente, nombre_ingrediente, unidad_medida, presentacion FROM INGREDIENTE ORDER BY nombre_ingrediente",
        accion="Panel chef: ingredientes",
    )
    recetas = consultar(
        """
        SELECT *
        FROM vw_recetas_chef
        ORDER BY platillo, nombre_ingrediente, numero_paso
        """,
        accion="Panel chef: recetas completas",
    )
    receta_ingredientes = consultar(
        """
        SELECT pi.id_platillo, i.nombre_ingrediente, i.unidad_medida, pi.cantidad
        FROM PLATILLO_INGREDIENTE pi
        INNER JOIN INGREDIENTE i ON i.id_ingrediente = pi.id_ingrediente
        ORDER BY i.nombre_ingrediente
        """,
        accion="Panel chef: ingredientes por receta",
    )
    receta_pasos = consultar(
        """
        SELECT id_platillo, numero_paso, instruccion, detalle_instruccion
        FROM INSTRUCCION
        ORDER BY id_platillo, numero_paso
        """,
        accion="Panel chef: pasos por receta",
    )
    return render_template(
        "chef.html",
        platillos=platillos,
        ingredientes=ingredientes,
        recetas=recetas,
        receta_ingredientes=receta_ingredientes,
        receta_pasos=receta_pasos,
    )


@app.post("/chef/platillos/<int:id_platillo>/ingredientes")
@sesion_requerida("CHEF")
def chef_agregar_ingrediente(id_platillo):
    sql = """
        INSERT INTO PLATILLO_INGREDIENTE (folio_pi, id_platillo, id_ingrediente, cantidad)
        VALUES (sq_platillo_ingrediente.NEXTVAL, :id_platillo, :id_ingrediente, :cantidad)
    """
    parametros = {
        "id_platillo": id_platillo,
        "id_ingrediente": int(request.form["id_ingrediente"]),
        "cantidad": float(request.form["cantidad"]),
    }
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(sql, parametros)
                conexion.commit()
                registrar_evento_sql("Chef: agregar ingrediente a receta", sql, parametros, filas=cursor.rowcount, resultado="Ingrediente relacionado; COMMIT")
        flash("Ingrediente agregado a la receta.", "exito")
    except Exception as error:
        registrar_evento_sql("Chef: agregar ingrediente a receta", sql, parametros, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo agregar ingrediente: {error}", "error")
    return redirect(url_for("panel_chef"))


@app.post("/chef/platillos/<int:id_platillo>/instrucciones")
@sesion_requerida("CHEF")
def chef_agregar_instruccion(id_platillo):
    sql_paso = "SELECT NVL(MAX(numero_paso), 0) + 1 AS siguiente_paso FROM INSTRUCCION WHERE id_platillo = :id_platillo"
    sql = """
        INSERT INTO INSTRUCCION (id_instruccion, id_platillo, numero_paso, instruccion, detalle_instruccion)
        VALUES (sq_instruccion.NEXTVAL, :id_platillo, :numero_paso, :instruccion, :detalle)
    """
    parametros = {
        "id_platillo": id_platillo,
        "instruccion": request.form["instruccion"],
        "detalle": request.form.get("detalle_instruccion"),
    }
    try:
        with abrir_conexion() as conexion:
            with conexion.cursor() as cursor:
                cursor.execute(sql_paso, {"id_platillo": id_platillo})
                numero_paso = int(cursor.fetchone()[0])
                registrar_evento_sql(
                    "Chef: calcular siguiente paso",
                    sql_paso,
                    {"id_platillo": id_platillo},
                    filas=1,
                    resultado=f"Siguiente paso {numero_paso}",
                    muestra=[{"siguiente_paso": numero_paso}],
                )
                parametros["numero_paso"] = numero_paso
                cursor.execute(sql, parametros)
                conexion.commit()
                registrar_evento_sql("Chef: agregar instruccion de receta", sql, parametros, filas=cursor.rowcount, resultado="Instruccion agregada; COMMIT")
        flash("Instruccion agregada.", "exito")
    except Exception as error:
        registrar_evento_sql("Chef: agregar instruccion de receta", sql, parametros, resultado="Error; ROLLBACK", error=error, tipo="TRANSACCION")
        flash(f"No se pudo agregar instruccion: {error}", "error")
    return redirect(url_for("panel_chef"))


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
        accion="Reporte: ingredientes necesarios",
    )
    cobranza = consultar("SELECT * FROM vw_eventos_no_finiquitados_21 ORDER BY fecha_evento", accion="Reporte: cobranza 21 dias")
    popularidad = consultar("SELECT * FROM vw_popularidad_platillos ORDER BY proyectos_demandados DESC, platillo", accion="Reporte: popularidad platillos")
    historial = consultar("SELECT * FROM vw_historial_cliente ORDER BY cliente, fecha_evento DESC", accion="Reporte: historial cliente")
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
        debug=os.getenv("FLASK_DEBUG", "N").upper() == "S",
        use_reloader=False,
    )
