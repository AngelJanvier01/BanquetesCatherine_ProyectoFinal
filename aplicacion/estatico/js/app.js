document.querySelectorAll('input[type="date"]').forEach((campo) => {
    if (!campo.value) {
        const hoy = new Date();
        hoy.setDate(hoy.getDate() + 7);
        campo.min = hoy.toISOString().slice(0, 10);
    }
});

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
            `<option value="${escaparHtml(salon.id_salon)}">${escaparHtml(salon.nombre)} · ${escaparHtml(salon.capacidad_maxima)} personas</option>`
        ).join("");
    });
    paquetes.forEach((select) => {
        select.innerHTML = `<option value="">Sin preferencia</option>` + (datos.paquetes || []).map((paquete) =>
            `<option value="${escaparHtml(paquete.id_paquete)}">${escaparHtml(paquete.nombre)} · $${escaparHtml(paquete.precio_base)}</option>`
        ).join("");
    });
    opcionesAgendaCargadas = true;
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
