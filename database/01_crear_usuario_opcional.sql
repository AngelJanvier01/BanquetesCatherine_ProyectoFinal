-- Ejecutar como SYS/SYSTEM solo si se desea crear un esquema nuevo.
-- Cambia la contrasena si tu profesor lo solicita.

CREATE USER BANQUETES_CATHERINE IDENTIFIED BY Catherine2026
    DEFAULT TABLESPACE USERS
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON USERS;

GRANT CONNECT, RESOURCE, CREATE VIEW, CREATE SYNONYM TO BANQUETES_CATHERINE;

-- En Oracle 12c+ a veces RESOURCE ya no otorga cuota efectiva; se deja explicito arriba.

