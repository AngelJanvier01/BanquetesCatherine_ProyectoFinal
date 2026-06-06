-- Datos de prueba para demo.
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';

-- Usuarios: password demo en README.
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'admin.catherine', 'pbkdf2_sha256$260000$banquetes2026$jyuTR0uJhoRjlMBqLi7n0T57qiaHL+CAlouleZvQ6b0=', 'GERENTE_ADMIN', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'gerente.lucia', 'pbkdf2_sha256$260000$banquetes2026$kJvbx30T9M9Wh566lhW/mz4Wi8deYLS9OOS7+bRrKtk=', 'GERENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'gerente.mateo', 'pbkdf2_sha256$260000$banquetes2026$kJvbx30T9M9Wh566lhW/mz4Wi8deYLS9OOS7+bRrKtk=', 'GERENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.demo', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.sofia', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.diego', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.valeria', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.andres', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.maria', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.jorge', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.paola', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.ricardo', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'cliente.elena', 'pbkdf2_sha256$260000$banquetes2026$scahtqKPVEah5jG3mRBkQEQmb5muLekk84hwCx3A6hk=', 'CLIENTE', 'S', SYSDATE);
INSERT INTO USUARIO VALUES (sq_usuario.NEXTVAL, 'chef.renata', 'pbkdf2_sha256$260000$banquetes2026$kJvbx30T9M9Wh566lhW/mz4Wi8deYLS9OOS7+bRrKtk=', 'CHEF', 'S', SYSDATE);

INSERT INTO GERENTE VALUES (sq_gerente.NEXTVAL, 1, 'Catherine Rivera', 'admin@banquetescatherine.local', '555-100-0001', 'ACTIVO');
INSERT INTO GERENTE VALUES (sq_gerente.NEXTVAL, 2, 'Lucia Montes', 'lucia@banquetescatherine.local', '555-100-0002', 'ACTIVO');
INSERT INTO GERENTE VALUES (sq_gerente.NEXTVAL, 3, 'Mateo Solis', 'mateo@banquetescatherine.local', '555-100-0003', 'VACACIONES');

INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 4, 'Ana', 'Lopez', 'ana.lopez@example.com', '555-200-0001', 'Av. Reforma 101', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 5, 'Sofia', 'Nava', 'sofia.nava@example.com', '555-200-0002', 'Calle Palma 22', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 6, 'Diego', 'Ramos', 'diego.ramos@example.com', '555-200-0003', 'Av. Rio 73', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 7, 'Valeria', 'Cruz', 'valeria.cruz@example.com', '555-200-0004', 'Calle Norte 9', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 8, 'Andres', 'Mora', 'andres.mora@example.com', '555-200-0005', 'Blvd. Central 15', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 9, 'Maria', 'Santos', 'maria.santos@example.com', '555-200-0006', 'Privada Olivo 4', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 10, 'Jorge', 'Paz', 'jorge.paz@example.com', '555-200-0007', 'Av. Sierra 211', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 11, 'Paola', 'Vega', 'paola.vega@example.com', '555-200-0008', 'Calle Luna 17', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 12, 'Ricardo', 'Leon', 'ricardo.leon@example.com', '555-200-0009', 'Calle Mar 88', SYSDATE);
INSERT INTO CLIENTE VALUES (sq_cliente.NEXTVAL, 13, 'Elena', 'Campos', 'elena.campos@example.com', '555-200-0010', 'Av. Jardin 42', SYSDATE);

INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'BROCHETA DE RES', 'Brochetas de res con vegetales asados', 185.00, 82.00, 4, 'FUERTE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'CHILES RELLENOS DE QUESO', 'Chiles poblanos rellenos con salsa de tomate', 145.00, 61.00, 4, 'FUERTE', 'VEGETARIANO', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'FILETE MIGNON CON CHAMPINONES', 'Filete de res con salsa de champinones', 260.00, 138.00, 6, 'FUERTE', 'PREMIUM', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'PESCADO AL VAPOR', 'Pescado blanco con verduras y salsa ligera', 175.00, 79.00, 4, 'FUERTE', 'LIGERO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'POLLO A LA CERVEZA', 'Pollo en salsa de cerveza y especias', 155.00, 65.00, 4, 'FUERTE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'CREMA DE ELOTE', 'Entrada cremosa con elote dulce', 75.00, 28.00, 8, 'ENTRADA', 'VEGETARIANO', 'BAJA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'ENSALADA MEDITERRANEA', 'Ensalada fresca con queso y aceitunas', 90.00, 34.00, 6, 'ENTRADA', 'LIGERO', 'BAJA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'PASTEL TRES LECHES', 'Postre clasico para eventos sociales', 65.00, 24.00, 10, 'POSTRE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'ASADO DE BODA ZACATECANO', 'Guiso tradicional de cerdo con chile rojo y especias', 210.00, 92.00, 6, 'FUERTE', 'REGIONAL', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'LOMO EN SALSA DE VINO TINTO', 'Lomo de cerdo glaseado con salsa de vino y hierbas', 235.00, 105.00, 6, 'FUERTE', 'FORMAL', 'ALTA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'CANAPES DE QUESO Y MEMBRILLO', 'Bocados frios para recepcion con queso regional y membrillo', 95.00, 36.00, 12, 'ENTRADA', 'REGIONAL', 'BAJA', 'img/hero-banquetes.png', 'S');
INSERT INTO PLATILLO VALUES (sq_platillo.NEXTVAL, 'MOUSSE DE CHOCOLATE', 'Postre individual con chocolate semiamargo y crema batida', 80.00, 31.00, 10, 'POSTRE', 'CLASICO', 'MEDIA', 'img/hero-banquetes.png', 'S');

INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'FILETE DE RES', 'GRAMOS', 'GRANEL', 'Corte fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHILE MORRON', 'PIEZAS', 'PIEZA', 'Rojo o verde');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CEBOLLA BLANCA', 'PIEZAS', 'PIEZA', 'Fresca');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'TOMATE', 'PIEZAS', 'PIEZA', 'Rojo');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'QUESO COTIJA', 'GRAMOS', 'PAQUETE', 'Queso regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'HUEVO', 'PIEZAS', 'PIEZA', 'Grande');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'BOTETE CHICO', 'GRAMOS', 'GRANEL', 'Pescado blanco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ZANAHORIA', 'PIEZAS', 'PIEZA', 'Fresca');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'APIO', 'PIEZAS', 'VARA', 'Fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'PECHUGA DE POLLO', 'PIEZAS', 'PIEZA', 'Sin piel');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CERVEZA', 'MILILITROS', 'LATA', 'Clara');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHAMPINONES', 'GRAMOS', 'LATA', 'Drenado');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'MANTEQUILLA', 'GRAMOS', 'BARRA', 'Sin sal');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ELOTE', 'GRAMOS', 'GRANEL', 'Dulce');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'LECHUGA', 'PIEZAS', 'PIEZA', 'Romana');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ACEITUNAS', 'GRAMOS', 'FRASCO', 'Sin hueso');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'HARINA', 'GRAMOS', 'BOLSA', 'Trigo');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'LECHE', 'MILILITROS', 'LITRO', 'Entera');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'AZUCAR', 'GRAMOS', 'BOLSA', 'Refinada');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'SAL', 'GRAMOS', 'GRANEL', 'Mesa');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'PIERNA DE CERDO', 'GRAMOS', 'GRANEL', 'Para asado regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHILE GUAJILLO', 'GRAMOS', 'BOLSA', 'Seco, limpio y desvenado');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHILE ANCHO', 'GRAMOS', 'BOLSA', 'Seco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'AJO', 'DIENTES', 'PIEZA', 'Fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'COMINO', 'GRAMOS', 'FRASCO', 'Molido');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'OREGANO', 'GRAMOS', 'FRASCO', 'Seco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'VINO TINTO', 'MILILITROS', 'BOTELLA', 'Para salsa');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'ROMERO', 'GRAMOS', 'MANOJO', 'Fresco');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'QUESO DE CABRA', 'GRAMOS', 'PAQUETE', 'Regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'MEMBRILLO', 'GRAMOS', 'BARRA', 'Dulce regional');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'PAN BAGUETTE', 'PIEZAS', 'PIEZA', 'Para canapes');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CHOCOLATE SEMIAMARGO', 'GRAMOS', 'BARRA', 'Reposteria');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'CREMA PARA BATIR', 'MILILITROS', 'LITRO', 'Refrigerada');
INSERT INTO INGREDIENTE VALUES (sq_ingrediente.NEXTVAL, 'GELATINA SIN SABOR', 'GRAMOS', 'SOBRE', 'Para mousse');

INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 1, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 2, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 3, 2);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 1, 20, 12);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 2, 5, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 2, 6, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 2, 4, 5);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 3, 1, 1200);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 3, 12, 300);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 3, 13, 80);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 4, 7, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 4, 8, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 4, 9, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 5, 10, 4);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 5, 11, 350);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 5, 13, 60);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 6, 14, 800);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 6, 18, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 7, 15, 3);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 7, 16, 120);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 8, 17, 400);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 8, 18, 1500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 8, 19, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 21, 1800);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 22, 120);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 23, 80);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 24, 6);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 9, 25, 8);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 21, 1400);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 27, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 28, 20);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 10, 13, 120);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 11, 29, 600);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 11, 30, 450);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 11, 31, 3);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 12, 32, 500);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 12, 33, 1000);
INSERT INTO PLATILLO_INGREDIENTE VALUES (sq_platillo_ingrediente.NEXTVAL, 12, 34, 20);

INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 1, 1, 'Cortar carne y verduras en piezas uniformes.', 'Mantener tamanio similar.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 1, 2, 'Armar brochetas y asar.', 'Revisar termino de carne.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 2, 1, 'Tatemar chiles y limpiar semillas.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 2, 2, 'Rellenar, capear y freir.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 3, 1, 'Sellar filete y preparar salsa.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 4, 1, 'Condimentar pescado y cocer al vapor.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 5, 1, 'Sofreir pollo, agregar cerveza y reducir.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 9, 1, 'Cocer la pierna de cerdo hasta suavizar.', 'Reservar caldo para la salsa.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 9, 2, 'Licuar chiles, ajo y especias; guisar con la carne.', 'Reducir hasta lograr textura espesa.');
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 10, 1, 'Sellar el lomo y preparar reduccion de vino tinto.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 10, 2, 'Hornear con romero y banar con salsa.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 11, 1, 'Cortar baguette, montar queso de cabra y membrillo.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 12, 1, 'Fundir chocolate y mezclar con crema batida.', NULL);
INSERT INTO INSTRUCCION VALUES (sq_instruccion.NEXTVAL, 12, 2, 'Refrigerar en porciones individuales.', NULL);

INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'BARRA DE BEBIDAS', 'Aguas frescas y refrescos por persona', 55.00, 'BEBIDA', 'POR_PERSONA', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'MESA DE POSTRES', 'Variedad de postres individuales', 85.00, 'POSTRE', 'POR_PERSONA', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'DECORACION FLORAL', 'Centros de mesa sencillos', 2500.00, 'MONTAJE', 'POR_EVENTO', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'SERVICIO DE MESEROS', 'Mesero adicional por evento', 900.00, 'SERVICIO', 'POR_EVENTO', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'LOZA PREMIUM', 'Loza y cristaleria elegante', 45.00, 'MONTAJE', 'POR_PERSONA', 'S');
INSERT INTO COMPLEMENTO VALUES (sq_complemento.NEXTVAL, 'TORNAFIESTA', 'Antojitos para cierre de evento', 95.00, 'ALIMENTO', 'POR_PERSONA', 'S');

INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Palacio de Convenciones Zacatecas', 'Blvd. Heroes de Chapultepec S/N, Ciudad Gobierno, Zacatecas', 'Ciudad Gobierno', 'Recinto amplio para congresos, graduaciones y banquetes grandes; convenio simulado para el proyecto escolar.', 'img/salon-zacatecas-convenciones.png', 'S', 68000.00, 900, 'Operaciones Palacio', '492-491-4575', 'operaciones@convencioneszacatecas.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Hotel Emporio Zacatecas - Terraza', 'Av. Hidalgo 703, Centro Historico, Zacatecas', 'Centro Historico', 'Terraza y salones para bodas, reuniones empresariales y cenas formales en zona centrica.', 'img/salon-zacatecas-colonial.png', 'S', 42000.00, 160, 'Grupos Emporio', '492-925-6500', 'zacatecas.grupos@emporio.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Meson de Jobito - Patio Colonial', 'Jardin de la Madre 108, Centro, Zacatecas', 'Centro Historico', 'Patio colonial para recepciones medianas, bodas civiles y eventos sociales con montaje elegante.', 'img/salon-zacatecas-colonial.png', 'S', 38000.00, 180, 'Ventas Jobito', '492-924-1722', 'ventas@mesondejobito.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'Corporativo La Cebada', 'Centro Historico, Zacatecas', 'Centro Historico', 'Salon con jardin y muros de cristal para bodas, XV anios y eventos sociales.', 'img/salon-zacatecas-jardin.png', 'S', 46000.00, 260, 'Coordinacion La Cebada', '492-000-2000', 'eventos@lacebada.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'La Esperanza Finca Jardin', 'Lopez de Nava 503, Zacatecas', 'Zona A', 'Finca jardin local con terraza rodeada de naturaleza para eventos familiares y recepciones.', 'img/salon-zacatecas-jardin.png', 'S', 30000.00, 120, 'Eventos La Esperanza', '492-559-2676', 'contacto@laesperanza.local', 'S');
INSERT INTO SALON VALUES (sq_salon.NEXTVAL, 'El Patio Salon de Eventos', 'Alejandro Volta 221, Zona A, Zacatecas', 'Zona A', 'Salon practico para eventos familiares, cumpleanios y reuniones privadas.', 'img/salon-zacatecas-colonial.png', 'S', 18000.00, 90, 'Administracion El Patio', '492-768-6129', 'salondeeventoselpatio@local', 'S');

INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Clasico', 'Entrada, fuerte, postre y bebidas para evento social', 420.00, 'SOCIAL', 35.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Ejecutivo', 'Servicio formal para reuniones de negocio con bebidas y meseros', 520.00, 'EMPRESARIAL', 38.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Boda Premium', 'Menu premium para bodas, bebidas, postres, loza y decoracion', 780.00, 'BODA', 45.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Paquete Ligero', 'Opciones frescas y balanceadas con bebidas', 390.00, 'LIGERO', 32.00, 'S', 'N', NULL, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Menu Ana Especial', 'Paquete personalizado para Ana Lopez con loza y bebidas', 610.00, 'PERSONALIZADO', 40.00, 'N', 'S', 1, 'S');
INSERT INTO PAQUETE VALUES (sq_paquete.NEXTVAL, 'Menu Sofia Vegetariano', 'Paquete personalizado vegetariano con barra de postres', 480.00, 'PERSONALIZADO', 34.00, 'N', 'S', 2, 'S');

INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 6, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 5, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 8, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 7, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 1, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 8, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 6, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 10, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 12, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 4, 7, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 4, 4, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 5, 6, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 5, 3, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 6, 7, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 6, 2, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 1, 11, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 2, 10, 1);
INSERT INTO PAQUETE_PLATILLO VALUES (sq_paquete_platillo.NEXTVAL, 3, 11, 1);

INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 1, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 1, 3, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 2, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 2, 4, 4);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 2, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 3, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 3, 5, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 4, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 5, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 5, 5, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 6, 1, 1);
INSERT INTO PAQUETE_COMPLEMENTO VALUES (sq_paquete_complemento.NEXTVAL, 6, 2, 1);

-- Solicitudes: algunas pendientes y una convertida para evidenciar separacion.
INSERT INTO SOLICITUD_SERVICIO (id_solicitud, nombre_contacto, correo, telefono, fecha_evento, numero_invitados, id_salon_preferido, id_paquete_preferido, mensaje, estatus, fecha_solicitud, id_gerente_asignado, observaciones, origen)
VALUES (sq_solicitud.NEXTVAL, 'Rosa Martinez', 'rosa@example.com', '555-444-0001', TRUNC(SYSDATE) + 40, 140, 2, 1, 'Solicito cotizacion para cumpleanios familiar.', 'PENDIENTE', SYSDATE, NULL, NULL, 'WEB');
INSERT INTO SOLICITUD_SERVICIO (id_solicitud, nombre_contacto, correo, telefono, fecha_evento, numero_invitados, id_salon_preferido, id_paquete_preferido, mensaje, estatus, fecha_solicitud, id_gerente_asignado, observaciones, origen)
VALUES (sq_solicitud.NEXTVAL, 'Empresa Nova', 'eventos@nova.example.com', '555-444-0002', TRUNC(SYSDATE) + 20, 500, 1, 2, 'Evento corporativo grande.', 'PENDIENTE', SYSDATE, NULL, NULL, 'WEB');
INSERT INTO SOLICITUD_SERVICIO (id_solicitud, nombre_contacto, correo, telefono, fecha_evento, numero_invitados, id_salon_preferido, id_paquete_preferido, mensaje, estatus, fecha_solicitud, id_gerente_asignado, observaciones, origen)
VALUES (sq_solicitud.NEXTVAL, 'Ana Lopez', 'ana.lopez@example.com', '555-200-0001', TRUNC(SYSDATE) + 30, 110, 1, 5, 'Boda jardin.', 'CONVERTIDA', SYSDATE - 3, 2, 'Convertida en proyecto 1', 'WEB');

-- 10 proyectos activos.
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, 3, 1, 2, 1, 5, 'Boda Ana y Luis', TRUNC(SYSDATE) + 30, 110, 146100.00, 'N', 'ACTIVO', 'hash-demo-1', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 2, 2, 2, 6, 'Cena Vegetariana Sofia', TRUNC(SYSDATE) + 15, 160, 141200.00, 'N', 'ACTIVO', 'hash-demo-2', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 3, 2, 5, 1, 'Comida Ejecutiva Diego', TRUNC(SYSDATE) + 3, 70, 65750.00, 'N', 'ACTIVO', 'hash-demo-3', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 4, 1, 3, 3, 'Recepcion Valeria', TRUNC(SYSDATE) + 21, 300, 330000.00, 'S', 'ACTIVO', 'hash-demo-4', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 5, 1, 4, 2, 'Foro Andres', TRUNC(SYSDATE) + 60, 220, 176100.00, 'N', 'ACTIVO', 'hash-demo-5', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 6, 2, 1, 4, 'Bautizo Maria', TRUNC(SYSDATE) + 8, 90, 108050.00, 'N', 'ACTIVO', 'hash-demo-6', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 7, 2, 2, 1, 'Aniversario Jorge', TRUNC(SYSDATE) + 10, 180, 130000.00, 'S', 'ACTIVO', 'hash-demo-7', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 8, 1, 4, 3, 'Boda Paola', TRUNC(SYSDATE) + 18, 280, 318700.00, 'N', 'ACTIVO', 'hash-demo-8', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 9, 1, 5, 4, 'Brunch Ricardo', TRUNC(SYSDATE) + 45, 75, 63375.00, 'N', 'ACTIVO', 'hash-demo-9', SYSDATE, SYSDATE);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 10, 2, 3, 2, 'Convencion Elena', TRUNC(SYSDATE) + 90, 420, 283100.00, 'N', 'ACTIVO', 'hash-demo-10', SYSDATE, SYSDATE);

-- 10 proyectos realizados.
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 1, 2, 2, 3, 'Boda Realizada Ana', TRUNC(SYSDATE) - 5, 180, 218200.00, 'S', 'REALIZADO', 'hash-demo-11', SYSDATE - 20, SYSDATE - 5);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 2, 2, 1, 1, 'Cumpleanios Sofia', TRUNC(SYSDATE) - 10, 90, 113250.00, 'S', 'REALIZADO', 'hash-demo-12', SYSDATE - 30, SYSDATE - 10);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 3, 1, 5, 4, 'Desayuno Diego', TRUNC(SYSDATE) - 20, 60, 56700.00, 'S', 'REALIZADO', 'hash-demo-13', SYSDATE - 40, SYSDATE - 20);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 4, 1, 3, 3, 'Gala Valeria', TRUNC(SYSDATE) - 35, 350, 378250.00, 'S', 'REALIZADO', 'hash-demo-14', SYSDATE - 60, SYSDATE - 35);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 5, 2, 4, 2, 'Capacitacion Andres', TRUNC(SYSDATE) - 50, 200, 164600.00, 'S', 'REALIZADO', 'hash-demo-15', SYSDATE - 80, SYSDATE - 50);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 6, 2, 1, 1, 'Primera Comunion Maria', TRUNC(SYSDATE) - 70, 100, 118000.00, 'S', 'REALIZADO', 'hash-demo-16', SYSDATE - 90, SYSDATE - 70);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 7, 1, 2, 4, 'Comida Familiar Jorge', TRUNC(SYSDATE) - 90, 130, 99850.00, 'S', 'REALIZADO', 'hash-demo-17', SYSDATE - 110, SYSDATE - 90);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 8, 1, 4, 3, 'Boda Civil Paola', TRUNC(SYSDATE) - 120, 250, 289750.00, 'S', 'REALIZADO', 'hash-demo-18', SYSDATE - 145, SYSDATE - 120);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 9, 2, 5, 2, 'Reunion Ricardo', TRUNC(SYSDATE) - 150, 65, 70975.00, 'S', 'REALIZADO', 'hash-demo-19', SYSDATE - 170, SYSDATE - 150);
INSERT INTO PROYECTO_EVENTO VALUES (sq_proyecto.NEXTVAL, NULL, 10, 2, 3, 3, 'Banquete Elena', TRUNC(SYSDATE) - 200, 400, 426500.00, 'S', 'REALIZADO', 'hash-demo-20', SYSDATE - 230, SYSDATE - 200);

-- Pagos para anticipos, abonos y liquidaciones.
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 1, 25000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 2, 'ANT-001');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 2, 20000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 4, 'ANT-002');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 3, 10000.00, 'ANTICIPO', 'EFECTIVO', SYSDATE - 1, 'ANT-003');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 4, 330000.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 7, 'LIQ-004');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 5, 50000.00, 'ANTICIPO', 'TARJETA', SYSDATE - 5, 'ANT-005');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 6, 15000.00, 'ANTICIPO', 'EFECTIVO', SYSDATE - 3, 'ANT-006');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 7, 130000.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 2, 'LIQ-007');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 8, 80000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 6, 'ANT-008');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 9, 5000.00, 'ANTICIPO', 'EFECTIVO', SYSDATE - 1, 'ANT-009');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 10, 60000.00, 'ANTICIPO', 'TRANSFERENCIA', SYSDATE - 4, 'ANT-010');

INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 11, 218200.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 6, 'LIQ-011');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 12, 113250.00, 'LIQUIDACION', 'EFECTIVO', SYSDATE - 11, 'LIQ-012');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 13, 56700.00, 'LIQUIDACION', 'TARJETA', SYSDATE - 21, 'LIQ-013');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 14, 378250.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 36, 'LIQ-014');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 15, 164600.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 51, 'LIQ-015');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 16, 118000.00, 'LIQUIDACION', 'EFECTIVO', SYSDATE - 71, 'LIQ-016');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 17, 99850.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 91, 'LIQ-017');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 18, 289750.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 121, 'LIQ-018');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 19, 70975.00, 'LIQUIDACION', 'EFECTIVO', SYSDATE - 151, 'LIQ-019');
INSERT INTO PAGO VALUES (sq_pago.NEXTVAL, 20, 426500.00, 'LIQUIDACION', 'TRANSFERENCIA', SYSDATE - 201, 'LIQ-020');

INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 1, 1, 110, 55.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 1, 3, 1, 2500.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 3, 4, 2, 900.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 8, 2, 280, 85.00);
INSERT INTO PROYECTO_COMPLEMENTO VALUES (sq_proyecto_complemento.NEXTVAL, 10, 5, 420, 45.00);

INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 1, 'Laura Hernandez', 'laura.invitada@example.com', '555-777-1001', 'CONFIRMADO', SYSDATE - 1, SYSDATE);
INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 1, 'Carlos Rivera', 'carlos.invitado@example.com', '555-777-1002', 'PENDIENTE', SYSDATE - 1, NULL);
INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 2, 'Martha Salas', 'martha.invitada@example.com', '555-777-1003', 'RECHAZADO', SYSDATE - 2, SYSDATE - 1);
INSERT INTO INVITADO_EVENTO VALUES (sq_invitado.NEXTVAL, 3, 'Equipo Ventas Nova', 'ventas.invitado@example.com', '555-777-1004', 'PENDIENTE', SYSDATE, NULL);

INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'AGENDA', 'Cita de degustacion', 'Degustacion de menu regional para 2 personas. Funcion de prueba del portal cliente.', 'PENDIENTE', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'PENDIENTE', 'Lista de pendientes', 'Revisar color de manteleria, confirmar musica y entregar croquis de mesa principal.', 'PENDIENTE', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'MONTAJE', 'Preferencia de montaje', 'Mesa de novios al centro, pista despejada y recepcion con canapes.', 'LISTO', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'MUSICA', 'Momentos musicales', 'Entrada de novios, vals familiar y cierre con tornafiesta.', 'PENDIENTE', SYSDATE);
INSERT INTO CORTESIA_EVENTO VALUES (sq_cortesia.NEXTVAL, 1, 'DIETA', 'Notas de dietas especiales', 'Considerar 4 invitados vegetarianos y 2 sin lactosa.', 'PENDIENTE', SYSDATE);

INSERT INTO NOTIFICACION VALUES (sq_notificacion.NEXTVAL, 'CLIENTE', 1, 1, NULL, 'WEB', 'Proyecto creado', 'Proyecto activo de prueba.', 'PENDIENTE', SYSDATE, NULL);
INSERT INTO NOTIFICACION VALUES (sq_notificacion.NEXTVAL, 'INSTALACION', NULL, 1, 1, 'CORREO', 'Evento confirmado', 'Preparar salon para boda.', 'PENDIENTE', SYSDATE, NULL);
INSERT INTO NOTIFICACION VALUES (sq_notificacion.NEXTVAL, 'GERENTE', 2, 2, NULL, 'WEB', 'Seguimiento de pago', 'Cliente con saldo pendiente.', 'PENDIENTE', SYSDATE, NULL);

BEGIN
    sp_generar_notificaciones_cobranza;
END;
/

COMMIT;
