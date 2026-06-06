@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where sqlplus >nul 2>nul
if errorlevel 1 (
    echo [ERROR] No se encontro SQLPlus.
    pause
    exit /b 1
)

if not exist ".estado" mkdir ".estado"

echo [INFO] Reinstalando SOLO el esquema BANQUETES_CATHERINE...
sqlplus -L / as sysdba @database/98_instalar_local_sysdba.sql > ".estado\instalacion_bd.log"
if errorlevel 1 (
    echo [ERROR] SQLPlus reporto un error.
    echo [INFO] Revisa el detalle en .estado\instalacion_bd.log
    pause
    exit /b 1
)

echo instalado > ".estado\bd_instalada.ok"
echo [OK] Base de datos reinstalada.
endlocal
