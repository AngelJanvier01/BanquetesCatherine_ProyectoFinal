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
