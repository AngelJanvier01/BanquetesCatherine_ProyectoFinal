# Documentacion Del Proyecto Banquetes Catherine

## Objetivo

Banquetes Catherine administra la operacion de eventos: solicitudes publicas, clientes, paquetes, salones, proyectos confirmados, invitados, pagos, cortesias, notificaciones y reportes.

## Pantallas

- `/banquetes`: pagina principal del servicio de banquetes.
- `/platillos`: catalogo publico de platillos que se usan en paquetes.
- `/complementos`: catalogo publico de extras.
- `/salones`: salones con convenio.
- `/cliente`: panel del cliente.
- `/gerente`: gestion de solicitudes, proyectos, pagos y paquetes personalizados.
- `/chef`: administracion tecnica de recetas, ingredientes, costos y procedimientos.
- `/consola-sql`: monitor de consultas para exposicion.

## Modelo De Datos Principal

- `SOLICITUD_SERVICIO` registra la peticion inicial del visitante.
- `PROYECTO_EVENTO` nace cuando gerencia convierte una solicitud en evento confirmado.
- `CLIENTE`, `GERENTE` y `USUARIO` separan credenciales, clientes y administradores.
- `PAQUETE`, `PAQUETE_PLATILLO` y `PAQUETE_COMPLEMENTO` arman la propuesta comercial.
- `PAGO` controla anticipo, abonos y liquidacion.
- `NOTIFICACION`, `INVITADO_EVENTO` y `CORTESIA_EVENTO` cubren seguimiento operativo.

## Relacion Con El Recetario

Banquetes usa las mismas recetas base que el recetario: `PLATILLO`, `INGREDIENTE`, `PLATILLO_INGREDIENTE` e `INSTRUCCION`. La diferencia esta en el uso:

- Banquetes usa precio, costo y paquetes para cotizar eventos.
- Recetario usa la publicacion del blog para mostrar historia, estado y recetas consultables.

