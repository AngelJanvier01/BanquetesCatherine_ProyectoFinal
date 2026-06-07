# Documentacion Del Recetario De Catherine

Autor del recetario:

- Angel Janvier Gonzalez Delgado

## Objetivo

El recetario permite que Catherine publique recetas de forma libre y que familiares o amigos las consulten desde una vista publica. La captura se hace desde la misma pagina con el boton de cambio entre `Vista publica` y `Vista Catherine`.

## Rutas

- `/`: portal inicial con botones para abrir Banquetes Catherine o Recetario de Catherine.
- `/recetario`: blog de recetas.
- `/recetario/recetas`: alta de recetas desde la vista Catherine.

## Flujo De Uso

1. El visitante entra a `/` y elige `Recetario de Catherine`.
2. La vista publica muestra recetas con categoria, dificultad, ingredientes y pasos.
3. Catherine presiona `Vista Catherine`.
4. Captura nombre, titulo publico, categoria, descripcion, historia, ingredientes y procedimiento.
5. Al guardar, la receta se inserta en las tablas compartidas y queda publicada o en borrador.

## Tablas Usadas

- `PLATILLO`: receta base y datos compartidos con banquetes.
- `INGREDIENTE`: catalogo normalizado de ingredientes.
- `PLATILLO_INGREDIENTE`: cantidad de cada ingrediente por receta.
- `INSTRUCCION`: pasos ordenados de preparacion.
- `PUBLICACION_RECETA`: metadatos del blog: titulo publico, historia, estatus, destacado y fechas.

## Reglas Del Recetario

- Una publicacion apunta a un solo platillo.
- Un platillo puede existir sin publicacion si solo se usa en banquetes o cocina interna.
- La vista publica solo muestra publicaciones con `estatus = 'PUBLICADA'`.
- Catherine puede dejar una receta en `BORRADOR`.
- Los ingredientes capturados desde el recetario se reutilizan si ya existen por nombre.

## Vistas SQL

- `vw_recetario_catherine`: muestra todas las publicaciones del recetario.
- `vw_recetario_publico`: muestra solo recetas publicadas.
- `vw_recetas_chef`: mantiene la vista tecnica del chef con ingredientes y pasos.

## Diagrama ER

El diagrama especifico del recetario esta en:

- `documentacion/diagrama_entidad_relacion_recetario.md`
- `documentacion/diagrama_entidad_relacion_recetario.mmd`

## Imagenes

Las fotos de los platillos de prueba se guardan localmente en `aplicacion/estatico/img/platillos/`.
Las fuentes usadas estan documentadas en `documentacion/atribuciones_imagenes_platillos.md`.
