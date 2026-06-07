# Diagrama Entidad-Relacion Del Recetario De Catherine

Autor del recetario:

- Angel Janvier Gonzalez Delgado

Este diagrama muestra el recetario como una extension del modelo existente. La receta vive en `PLATILLO`; la entrada de blog vive en `PUBLICACION_RECETA`. Con esto se comparte la misma base entre banquetes y recetario sin duplicar ingredientes ni pasos.

```mermaid
erDiagram
    PLATILLO ||--o| PUBLICACION_RECETA : "tiene entrada de blog"
    PLATILLO ||--o{ PLATILLO_INGREDIENTE : "usa"
    INGREDIENTE ||--o{ PLATILLO_INGREDIENTE : "aparece en"
    PLATILLO ||--o{ INSTRUCCION : "se explica con"
    PAQUETE ||--o{ PAQUETE_PLATILLO : "incluye"
    PLATILLO ||--o{ PAQUETE_PLATILLO : "tambien se vende en"
    CLIENTE ||--o{ PAQUETE : "recibe menu personalizado"
    PAQUETE ||--o{ PROYECTO_EVENTO : "se contrata en"
    PROYECTO_EVENTO ||--o{ PAGO : "genera"
    PROYECTO_EVENTO ||--o{ NOTIFICACION : "notifica"

    PLATILLO {
        NUMBER id_platillo PK
        VARCHAR2 nombre UK
        VARCHAR2 descripcion
        NUMBER precio
        NUMBER costo_estimado
        NUMBER porciones_base
        VARCHAR2 categoria
        VARCHAR2 tipo_dieta
        VARCHAR2 dificultad
        VARCHAR2 foto_url
        CHAR activo
    }

    PUBLICACION_RECETA {
        NUMBER id_publicacion PK
        NUMBER id_platillo FK
        VARCHAR2 titulo_publico
        VARCHAR2 historia
        VARCHAR2 estatus
        CHAR destacado
        DATE fecha_publicacion
        DATE fecha_actualizacion
    }

    INGREDIENTE {
        NUMBER id_ingrediente PK
        VARCHAR2 nombre_ingrediente UK
        VARCHAR2 unidad_medida
        VARCHAR2 presentacion
        VARCHAR2 observacion
    }

    PLATILLO_INGREDIENTE {
        NUMBER folio_pi PK
        NUMBER id_platillo FK
        NUMBER id_ingrediente FK
        NUMBER cantidad
    }

    INSTRUCCION {
        NUMBER id_instruccion PK
        NUMBER id_platillo FK
        NUMBER numero_paso
        VARCHAR2 instruccion
        VARCHAR2 detalle_instruccion
    }

    PAQUETE {
        NUMBER id_paquete PK
        VARCHAR2 nombre
        NUMBER precio_base
        CHAR visible_publico
        CHAR personalizado
        NUMBER id_cliente FK
        CHAR activo
    }

    PAQUETE_PLATILLO {
        NUMBER id_paquete_platillo PK
        NUMBER id_paquete FK
        NUMBER id_platillo FK
        NUMBER cantidad
    }

    CLIENTE {
        NUMBER id_cliente PK
        NUMBER id_usuario FK
        VARCHAR2 nombre
        VARCHAR2 apellido
        VARCHAR2 correo UK
    }

    PROYECTO_EVENTO {
        NUMBER id_proyecto PK
        NUMBER id_cliente FK
        NUMBER id_paquete FK
        VARCHAR2 nombre_evento
        DATE fecha_evento
        NUMBER numero_invitados
        NUMBER total_estimado
    }

    PAGO {
        NUMBER id_pago PK
        NUMBER id_proyecto FK
        NUMBER monto
        VARCHAR2 tipo_pago
        VARCHAR2 metodo_pago
    }

    NOTIFICACION {
        NUMBER id_notificacion PK
        NUMBER id_proyecto FK
        VARCHAR2 tipo_destinatario
        VARCHAR2 asunto
        VARCHAR2 estatus
    }
```

## Reglas Que Satisface

- `PUBLICACION_RECETA.id_platillo` es unico: una receta base tiene como maximo una entrada de blog.
- `PUBLICACION_RECETA.estatus` permite `BORRADOR`, `PUBLICADA` y `ARCHIVADA`.
- `vw_recetario_publico` filtra solo `PUBLICADA`.
- `PLATILLO_INGREDIENTE` evita repetir el mismo ingrediente dentro de la misma receta.
- `INSTRUCCION` ordena el procedimiento por `numero_paso`.
- La misma receta puede aparecer en un paquete de banquetes mediante `PAQUETE_PLATILLO`.
- Los costos y precios siguen disponibles para banquetes, pero el recetario puede capturar recetas sin costo comercial.
