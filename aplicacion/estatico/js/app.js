document.querySelectorAll('input[type="date"]').forEach((campo) => {
    if (!campo.value) {
        const hoy = new Date();
        hoy.setDate(hoy.getDate() + 7);
        campo.min = hoy.toISOString().slice(0, 10);
    }
});

