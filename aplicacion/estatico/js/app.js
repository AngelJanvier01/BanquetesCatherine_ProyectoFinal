document.querySelectorAll('input[type="date"]').forEach((campo) => {
    if (!campo.value) {
        const hoy = new Date();
        hoy.setDate(hoy.getDate() + 7);
        campo.min = hoy.toISOString().slice(0, 10);
    }
});

const barra = document.querySelector(".barra");
window.addEventListener("scroll", () => {
    if (!barra) return;
    barra.classList.toggle("barra-elevada", window.scrollY > 12);
});

const elementosAnimados = document.querySelectorAll(".animar-entrada");
if ("IntersectionObserver" in window) {
    const observadorEntrada = new IntersectionObserver((entradas) => {
        entradas.forEach((entrada) => {
            if (entrada.isIntersecting) {
                entrada.target.classList.add("visible");
                observadorEntrada.unobserve(entrada.target);
            }
        });
    }, { threshold: 0.14 });
    elementosAnimados.forEach((elemento) => observadorEntrada.observe(elemento));
} else {
    elementosAnimados.forEach((elemento) => elemento.classList.add("visible"));
}

const terminalSql = document.getElementById("terminalSql");
const autoActualizar = document.getElementById("autoActualizar");

function escaparHtml(valor) {
    return String(valor ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}

function formatoMoneda(valor) {
    const numero = Number(valor || 0);
    return numero.toLocaleString("es-MX", { style: "currency", currency: "MXN" });
}

function pintarTablaResultado(muestra) {
    if (!Array.isArray(muestra) || !muestra.length) return "";
    const columnas = Object.keys(muestra[0]);
    return `
        <div class="resultado-sql">
            <table>
                <thead><tr>${columnas.map((columna) => `<th>${escaparHtml(columna)}</th>`).join("")}</tr></thead>
                <tbody>
                    ${muestra.map((fila) => `
                        <tr>${columnas.map((columna) => `<td>${escaparHtml(fila[columna])}</td>`).join("")}</tr>
                    `).join("")}
                </tbody>
            </table>
        </div>`;
}

function pintarEventosSql(eventos) {
    if (!terminalSql) return;
    if (!eventos.length) {
        terminalSql.innerHTML = `
            <article class="evento-sql">
                <header><span>[--:--:--]</span><strong>Sin eventos todavia</strong><em>SISTEMA</em></header>
                <pre>-- Navega por el sitio para ver las consultas SQL y procedimientos PL/SQL ejecutados.</pre>
            </article>`;
        return;
    }
    terminalSql.innerHTML = eventos.map((evento) => `
        <article class="evento-sql ${evento.error ? "evento-error" : ""}">
            <header>
                <span>[${escaparHtml(evento.hora)}]</span>
                <strong>${escaparHtml(evento.accion)}</strong>
                <em>${escaparHtml(evento.tipo)}</em>
            </header>
            <pre>${escaparHtml(evento.sentencia)}</pre>
            ${evento.parametros && Object.keys(evento.parametros).length
                ? `<p><b>Parametros:</b> ${escaparHtml(JSON.stringify(evento.parametros))}</p>`
                : ""}
            <p><b>Resultado:</b> ${escaparHtml(evento.resultado || "OK")}
                ${evento.error ? ` - ${escaparHtml(evento.error)}` : ""}
                ${evento.filas !== null && evento.filas !== undefined ? ` - ${escaparHtml(evento.filas)} fila(s)` : ""}
            </p>
            ${pintarTablaResultado(evento.muestra)}
        </article>`).join("");
    terminalSql.scrollTop = terminalSql.scrollHeight;
}

async function actualizarConsolaSql() {
    if (!terminalSql || (autoActualizar && !autoActualizar.checked)) return;
    const respuesta = await fetch("/api/consola-sql", { cache: "no-store" });
    if (!respuesta.ok) return;
    pintarEventosSql(await respuesta.json());
}

if (terminalSql) {
    terminalSql.scrollTop = terminalSql.scrollHeight;
    setInterval(actualizarConsolaSql, 1800);
}

const modalAgenda = document.getElementById("modalAgenda");
let opcionesAgendaCargadas = false;

async function cargarOpcionesAgenda() {
    if (opcionesAgendaCargadas) return;
    const respuesta = await fetch("/api/opciones-solicitud", { cache: "no-store" });
    if (!respuesta.ok) return;
    const datos = await respuesta.json();
    const salones = document.querySelectorAll("[data-opciones-salones]");
    const paquetes = document.querySelectorAll("[data-opciones-paquetes]");
    salones.forEach((select) => {
        select.innerHTML = `<option value="">Sin preferencia</option>` + (datos.salones || []).map((salon) =>
            `<option value="${escaparHtml(salon.id_salon)}">${escaparHtml(salon.nombre)} - ${escaparHtml(salon.capacidad_maxima)} personas</option>`
        ).join("");
    });
    paquetes.forEach((select) => {
        select.innerHTML = `<option value="">Sin preferencia</option>` + (datos.paquetes || []).map((paquete) =>
            `<option value="${escaparHtml(paquete.id_paquete)}">${escaparHtml(paquete.nombre)} - $${escaparHtml(paquete.precio_base)} p/p</option>`
        ).join("");
    });
    opcionesAgendaCargadas = true;
    actualizarCotizacionAgenda();
}

function abrirAgenda() {
    if (!modalAgenda) return;
    cargarOpcionesAgenda();
    modalAgenda.classList.add("abierto");
    modalAgenda.setAttribute("aria-hidden", "false");
}

function cerrarAgenda() {
    if (!modalAgenda) return;
    modalAgenda.classList.remove("abierto");
    modalAgenda.setAttribute("aria-hidden", "true");
}

document.querySelectorAll(".abrir-agenda").forEach((boton) => {
    boton.addEventListener("click", abrirAgenda);
});

document.querySelectorAll("[data-cerrar-agenda]").forEach((elemento) => {
    elemento.addEventListener("click", cerrarAgenda);
});

document.addEventListener("keydown", (evento) => {
    if (evento.key === "Escape") cerrarAgenda();
});

async function pedirCotizacion(numeroInvitados, idSalon, idPaquete) {
    if (!numeroInvitados || !idSalon || !idPaquete) return null;
    const parametros = new URLSearchParams({
        numero_invitados: numeroInvitados,
        id_salon: idSalon,
        id_paquete: idPaquete,
    });
    const respuesta = await fetch(`/api/cotizacion?${parametros.toString()}`, { cache: "no-store" });
    if (!respuesta.ok) return null;
    return respuesta.json();
}

async function actualizarCotizacionAgenda() {
    const resumen = document.getElementById("resumenCotizacion");
    const formulario = modalAgenda ? modalAgenda.querySelector("form") : null;
    if (!resumen || !formulario) return;
    const invitados = formulario.querySelector('[name="numero_invitados"]')?.value;
    const salon = formulario.querySelector('[name="id_salon_preferido"]')?.value;
    const paquete = formulario.querySelector('[name="id_paquete_preferido"]')?.value;
    if (!invitados || !salon || !paquete) {
        resumen.textContent = "Selecciona invitados, salon y paquete para ver una estimacion.";
        return;
    }
    resumen.textContent = "Calculando estimacion...";
    const datos = await pedirCotizacion(invitados, salon, paquete);
    if (!datos || datos.error || datos.total_estimado === null) {
        resumen.textContent = "No se pudo calcular con esas opciones.";
        return;
    }
    resumen.textContent = `Estimacion: ${formatoMoneda(datos.total_estimado)} en total, ${formatoMoneda(datos.costo_por_persona)} por persona antes de ajustes finales.`;
}

if (modalAgenda) {
    modalAgenda.querySelectorAll('input[name="numero_invitados"], select[name="id_salon_preferido"], select[name="id_paquete_preferido"]').forEach((campo) => {
        campo.addEventListener("input", actualizarCotizacionAgenda);
        campo.addEventListener("change", actualizarCotizacionAgenda);
    });
}

const campoUsuarioLogin = document.getElementById("campoUsuarioLogin");
const campoContrasenaLogin = document.getElementById("campoContrasenaLogin");

document.querySelectorAll("[data-login-usuario]").forEach((boton) => {
    boton.addEventListener("click", () => {
        if (!campoUsuarioLogin || !campoContrasenaLogin) return;
        campoUsuarioLogin.value = boton.dataset.loginUsuario || "";
        campoContrasenaLogin.value = boton.dataset.loginContrasena || "";
        campoUsuarioLogin.dispatchEvent(new Event("input", { bubbles: true }));
        campoContrasenaLogin.dispatchEvent(new Event("input", { bubbles: true }));
        campoContrasenaLogin.focus();
    });
});

function activarFiltro(botones, botonActivo) {
    botones.forEach((boton) => boton.classList.toggle("activo", boton === botonActivo));
}

const botonesPlatillos = document.querySelectorAll("[data-filtro-platillo]");
const tarjetasPlatillos = document.querySelectorAll("[data-tarjeta-platillo]");
const conteoPlatillos = document.getElementById("conteoPlatillos");

function filtrarPlatillos(categoria) {
    let visibles = 0;
    tarjetasPlatillos.forEach((tarjeta) => {
        const mostrar = categoria === "TODOS" || tarjeta.dataset.categoria === categoria;
        tarjeta.hidden = !mostrar;
        if (mostrar) visibles += 1;
    });
    if (conteoPlatillos) {
        conteoPlatillos.textContent = `${visibles} opcion${visibles === 1 ? "" : "es"}`;
    }
}

botonesPlatillos.forEach((boton) => {
    boton.addEventListener("click", () => {
        activarFiltro(botonesPlatillos, boton);
        filtrarPlatillos(boton.dataset.filtroPlatillo);
    });
});

if (tarjetasPlatillos.length) filtrarPlatillos("TODOS");

const botonesSalones = document.querySelectorAll("[data-filtro-salon]");
const tarjetasSalones = document.querySelectorAll("[data-tarjeta-salon]");
const conteoSalones = document.getElementById("conteoSalones");

function filtrarSalones(valor) {
    let visibles = 0;
    tarjetasSalones.forEach((tarjeta) => {
        const capacidad = Number(tarjeta.dataset.capacidad || 0);
        let mostrar = valor === "TODOS";
        if (valor === "120") mostrar = capacidad <= 120;
        if (valor === "250") mostrar = capacidad > 120 && capacidad <= 250;
        if (valor === "500") mostrar = capacidad > 250;
        tarjeta.hidden = !mostrar;
        if (mostrar) visibles += 1;
    });
    if (conteoSalones) {
        conteoSalones.textContent = `${visibles} salon${visibles === 1 ? "" : "es"}`;
    }
}

botonesSalones.forEach((boton) => {
    boton.addEventListener("click", () => {
        activarFiltro(botonesSalones, boton);
        filtrarSalones(boton.dataset.filtroSalon);
    });
});

if (tarjetasSalones.length) filtrarSalones("TODOS");

document.querySelectorAll("[data-cotizacion-proyecto]").forEach((formulario) => {
    const entrada = formulario.querySelector('[name="numero_invitados"]');
    const resumen = formulario.querySelector("[data-resumen-proyecto]");
    async function actualizar() {
        if (!entrada || !resumen) return;
        const datos = await pedirCotizacion(entrada.value, formulario.dataset.idSalon, formulario.dataset.idPaquete);
        if (!datos || datos.error || datos.total_estimado === null) {
            resumen.textContent = "No se pudo recalcular.";
            return;
        }
        resumen.textContent = `Nuevo estimado: ${formatoMoneda(datos.total_estimado)} - ${formatoMoneda(datos.costo_por_persona)} por persona.`;
    }
    entrada?.addEventListener("input", actualizar);
});

document.querySelectorAll("[data-menu-builder]").forEach((formulario) => {
    const resumen = formulario.querySelector("[data-resumen-menu]");
    const margen = formulario.querySelector('[name="margen_ganancia"]');
    const precioManual = formulario.querySelector('[name="precio_base"]');
    const controles = formulario.querySelectorAll('input[type="checkbox"], [name="margen_ganancia"], [name="precio_base"]');
    function actualizar() {
        const seleccionados = formulario.querySelectorAll('input[type="checkbox"]:checked');
        let costo = 0;
        seleccionados.forEach((entrada) => {
            costo += Number(entrada.dataset.costo || 0);
        });
        const margenValor = Number(margen?.value || 0);
        const sugerido = costo * (1 + margenValor / 100);
        const manual = Number(precioManual?.value || 0);
        if (resumen) {
            resumen.textContent = manual > 0
                ? `Precio manual: ${formatoMoneda(manual)} por persona. Costo estimado base: ${formatoMoneda(costo)}.`
                : `Precio sugerido: ${formatoMoneda(sugerido)} por persona con ${margenValor}% de margen.`;
        }
    }
    controles.forEach((control) => {
        control.addEventListener("input", actualizar);
        control.addEventListener("change", actualizar);
    });
    actualizar();
});

document.querySelectorAll("[data-receta-builder]").forEach((formulario) => {
    const costo = formulario.querySelector("[data-costo-receta]");
    const margen = formulario.querySelector("[data-margen-receta]");
    const precio = formulario.querySelector("[data-precio-receta]");
    const resumen = formulario.querySelector("[data-resumen-receta]");
    const selectorIngrediente = formulario.querySelector("[data-selector-ingrediente]");
    const cantidadIngrediente = formulario.querySelector("[data-cantidad-ingrediente]");
    const listaIngredientes = formulario.querySelector("[data-lista-ingredientes]");
    const textoPaso = formulario.querySelector("[data-texto-paso]");
    const detallePaso = formulario.querySelector("[data-detalle-paso]");
    const listaPasos = formulario.querySelector("[data-lista-pasos]");

    function actualizarPrecio() {
        const sugerido = Number(costo?.value || 0) * (1 + Number(margen?.value || 0) / 100);
        if (resumen) resumen.textContent = `Precio sugerido por persona: ${formatoMoneda(sugerido)}. Puedes capturar un precio manual si lo necesitas.`;
        if (precio && !precio.value) precio.placeholder = formatoMoneda(sugerido);
    }

    formulario.querySelector("[data-agregar-ingrediente]")?.addEventListener("click", () => {
        if (!selectorIngrediente || !cantidadIngrediente || !listaIngredientes || !cantidadIngrediente.value) return;
        const opcion = selectorIngrediente.selectedOptions[0];
        const id = selectorIngrediente.value;
        const nombre = opcion?.dataset.nombre || opcion?.textContent || "Ingrediente";
        const unidad = opcion?.dataset.unidad || "";
        const cantidad = cantidadIngrediente.value;
        const fila = document.createElement("div");
        fila.className = "item-constructor";
        fila.innerHTML = `
            <span>${escaparHtml(nombre)} - ${escaparHtml(cantidad)} ${escaparHtml(unidad)} por persona</span>
            <input type="hidden" name="ingredientes_receta" value="${escaparHtml(id)}">
            <input type="hidden" name="cantidades_receta" value="${escaparHtml(cantidad)}">
            <button type="button" data-remover-elemento>x</button>`;
        listaIngredientes.appendChild(fila);
        cantidadIngrediente.value = "";
    });

    formulario.querySelector("[data-agregar-paso]")?.addEventListener("click", () => {
        if (!textoPaso || !listaPasos || !textoPaso.value.trim()) return;
        const paso = textoPaso.value.trim();
        const detalle = detallePaso?.value.trim() || "";
        const fila = document.createElement("div");
        fila.className = "item-constructor";
        fila.innerHTML = `
            <span>${escaparHtml(paso)}${detalle ? ` - ${escaparHtml(detalle)}` : ""}</span>
            <input type="hidden" name="pasos_receta" value="${escaparHtml(paso)}">
            <input type="hidden" name="detalles_paso" value="${escaparHtml(detalle)}">
            <button type="button" data-remover-elemento>x</button>`;
        listaPasos.appendChild(fila);
        textoPaso.value = "";
        if (detallePaso) detallePaso.value = "";
    });

    formulario.addEventListener("click", (evento) => {
        if (evento.target.matches("[data-remover-elemento]")) {
            evento.target.closest(".item-constructor")?.remove();
        }
    });

    [costo, margen, precio].forEach((campo) => campo?.addEventListener("input", actualizarPrecio));
    actualizarPrecio();
});

function cerrarRecetas() {
    document.querySelectorAll(".modal-receta.abierto").forEach((modal) => {
        modal.classList.remove("abierto");
        modal.setAttribute("aria-hidden", "true");
    });
}

document.querySelectorAll("[data-abrir-receta]").forEach((boton) => {
    boton.addEventListener("click", () => {
        const modal = document.getElementById(boton.dataset.abrirReceta);
        if (!modal) return;
        modal.classList.add("abierto");
        modal.setAttribute("aria-hidden", "false");
    });
});

document.querySelectorAll("[data-cerrar-receta]").forEach((elemento) => {
    elemento.addEventListener("click", cerrarRecetas);
});

document.addEventListener("keydown", (evento) => {
    if (evento.key === "Escape") cerrarRecetas();
});
