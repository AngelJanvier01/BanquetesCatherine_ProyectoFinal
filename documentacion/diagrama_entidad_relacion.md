# Diagrama Entidad-Relacion - Catherine: Banquetes Y Recetario

Autores:

- Angel Janvier Gonzalez Delgado
- Carlos Alberto Gutierrez Flores

Este diagrama muestra el modelo entidad-relacion integrado. Banquetes y el recetario comparten `PLATILLO`, `INGREDIENTE`, `PLATILLO_INGREDIENTE` e `INSTRUCCION`; el blog agrega `PUBLICACION_RECETA` para manejar titulo publico, historia, estado y destacado sin duplicar la receta base.

```mermaid
erDiagram
    USUARIO {
        NUMBER id_usuario PK
        VARCHAR2 nombre_usuario UK
        VARCHAR2 hash_contrasena
        VARCHAR2 rol
        CHAR activo
        DATE fecha_creacion
    }

    CLIENTE {
        NUMBER id_cliente PK
        NUMBER id_usuario FK
        VARCHAR2 nombre
        VARCHAR2 apellido
        VARCHAR2 correo UK
        VARCHAR2 telefono
        VARCHAR2 direccion
        DATE fecha_registro
    }

    GERENTE {
        NUMBER id_gerente PK
        NUMBER id_usuario FK
        VARCHAR2 nombre
        VARCHAR2 correo UK
        VARCHAR2 telefono
        VARCHAR2 estatus
    }

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

    COMPLEMENTO {
        NUMBER id_complemento PK
        VARCHAR2 nombre UK
        VARCHAR2 descripcion
        NUMBER precio
        VARCHAR2 tipo_complemento
        VARCHAR2 tipo_cobro
        CHAR activo
    }

    SALON {
        NUMBER id_salon PK
        VARCHAR2 nombre UK
        VARCHAR2 direccion
        VARCHAR2 zona
        VARCHAR2 descripcion
        CHAR convenio_activo
        NUMBER costo_renta
        NUMBER capacidad_maxima
        VARCHAR2 contacto_instalacion
        VARCHAR2 telefono_contacto
        VARCHAR2 correo_contacto
        CHAR activo
    }

    PAQUETE {
        NUMBER id_paquete PK
        VARCHAR2 nombre
        VARCHAR2 descripcion
        NUMBER precio_base
        VARCHAR2 tipo_paquete
        NUMBER margen_ganancia
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

    PAQUETE_COMPLEMENTO {
        NUMBER id_paquete_complemento PK
        NUMBER id_paquete FK
        NUMBER id_complemento FK
        NUMBER cantidad
    }

    SOLICITUD_SERVICIO {
        NUMBER id_solicitud PK
        VARCHAR2 nombre_contacto
        VARCHAR2 correo
        VARCHAR2 telefono
        DATE fecha_evento
        NUMBER numero_invitados
        NUMBER id_salon_preferido FK
        NUMBER id_paquete_preferido FK
        VARCHAR2 estatus
        DATE fecha_solicitud
        NUMBER id_gerente_asignado FK
        VARCHAR2 origen
    }

    PROYECTO_EVENTO {
        NUMBER id_proyecto PK
        NUMBER id_solicitud FK
        NUMBER id_cliente FK
        NUMBER id_gerente FK
        NUMBER id_salon FK
        NUMBER id_paquete FK
        VARCHAR2 nombre_evento
        DATE fecha_evento
        NUMBER numero_invitados
        NUMBER total_estimado
        CHAR finiquitado
        VARCHAR2 estatus
    }

    PROYECTO_COMPLEMENTO {
        NUMBER id_proyecto_complemento PK
        NUMBER id_proyecto FK
        NUMBER id_complemento FK
        NUMBER cantidad
        NUMBER precio_unitario
    }

    PAGO {
        NUMBER id_pago PK
        NUMBER id_proyecto FK
        NUMBER monto
        VARCHAR2 tipo_pago
        VARCHAR2 metodo_pago
        DATE fecha_pago
        VARCHAR2 referencia UK
    }

    INVITADO_EVENTO {
        NUMBER id_invitado PK
        NUMBER id_proyecto FK
        VARCHAR2 nombre
        VARCHAR2 correo
        VARCHAR2 telefono
        VARCHAR2 estatus_confirmacion
        DATE fecha_invitacion
        DATE fecha_respuesta
    }

    CORTESIA_EVENTO {
        NUMBER id_cortesia PK
        NUMBER id_proyecto FK
        VARCHAR2 tipo_cortesia
        VARCHAR2 titulo
        VARCHAR2 detalle
        VARCHAR2 estatus
        DATE fecha_registro
    }

    NOTIFICACION {
        NUMBER id_notificacion PK
        VARCHAR2 tipo_destinatario
        NUMBER id_destinatario
        NUMBER id_proyecto FK
        NUMBER id_salon FK
        VARCHAR2 canal
        VARCHAR2 asunto
        VARCHAR2 mensaje
        VARCHAR2 estatus
        DATE fecha_creacion
        DATE fecha_lectura
    }

    USUARIO ||--o| CLIENTE : "credenciales cliente"
    USUARIO ||--o| GERENTE : "credenciales gerente"

    CLIENTE ||--o{ PAQUETE : "menus personalizados"
    CLIENTE ||--o{ PROYECTO_EVENTO : "contrata"
    GERENTE ||--o{ SOLICITUD_SERVICIO : "atiende"
    GERENTE ||--o{ PROYECTO_EVENTO : "administra"

    PLATILLO ||--o{ PLATILLO_INGREDIENTE : "usa"
    INGREDIENTE ||--o{ PLATILLO_INGREDIENTE : "integra"
    PLATILLO ||--o{ INSTRUCCION : "se prepara con"
    PLATILLO ||--o| PUBLICACION_RECETA : "se publica como"

    PAQUETE ||--o{ PAQUETE_PLATILLO : "incluye"
    PLATILLO ||--o{ PAQUETE_PLATILLO : "forma parte de"
    PAQUETE ||--o{ PAQUETE_COMPLEMENTO : "incluye"
    COMPLEMENTO ||--o{ PAQUETE_COMPLEMENTO : "forma parte de"

    SALON ||--o{ SOLICITUD_SERVICIO : "preferido en"
    PAQUETE ||--o{ SOLICITUD_SERVICIO : "preferido en"
    SOLICITUD_SERVICIO ||--o| PROYECTO_EVENTO : "se convierte en"

    SALON ||--o{ PROYECTO_EVENTO : "recibe"
    PAQUETE ||--o{ PROYECTO_EVENTO : "se contrata en"
    PROYECTO_EVENTO ||--o{ PROYECTO_COMPLEMENTO : "agrega extras"
    COMPLEMENTO ||--o{ PROYECTO_COMPLEMENTO : "extra contratado"
    PROYECTO_EVENTO ||--o{ PAGO : "recibe"
    PROYECTO_EVENTO ||--o{ INVITADO_EVENTO : "gestiona invitados"
    PROYECTO_EVENTO ||--o{ CORTESIA_EVENTO : "ofrece cortesia"
    PROYECTO_EVENTO ||--o{ NOTIFICACION : "genera"
    SALON ||--o{ NOTIFICACION : "recibe aviso instalacion"
```

## Reglas Que Refleja El Diagrama

- `SOLICITUD_SERVICIO` y `PROYECTO_EVENTO` estan separados: la solicitud es una peticion inicial y el proyecto nace cuando gerencia confirma el servicio.
- `PLATILLO`, `INGREDIENTE`, `PLATILLO_INGREDIENTE` e `INSTRUCCION` forman la receta tecnica compartida.
- `PUBLICACION_RECETA` convierte un platillo en entrada de blog con titulo publico, historia, estatus y marca de destacado.
- Las cantidades de `PLATILLO_INGREDIENTE.cantidad` son por persona; si el evento tiene 100 invitados, el reporte multiplica por 100.
- `PAQUETE` se arma con platillos existentes y complementos existentes.
- Los paquetes personalizados usan `personalizado = 'S'`, `visible_publico = 'N'` e `id_cliente` obligatorio.
- `PAGO` permite anticipo, abonos y liquidacion; el saldo se calcula contra `total_estimado`.
- `NOTIFICACION` registra avisos para clientes, gerentes, cobranza e instalaciones.
