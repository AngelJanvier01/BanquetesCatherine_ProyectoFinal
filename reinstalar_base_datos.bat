@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

if not exist ".estado" mkdir ".estado"

set "SQLPLUS=sqlplus"
where sqlplus >nul 2>nul
if errorlevel 1 (
    echo [INFO] SQLPlus no esta en PATH. Buscando en C:\app...
    for /f "delims=" %%S in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path 'C:\app' -Recurse -Filter sqlplus.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName"') do set "SQLPLUS=%%S"
    if not exist "!SQLPLUS!" (
        echo [ERROR] No se encontro SQLPlus.
        pause
        exit /b 1
    )
)

echo [INFO] Reinstalando SOLO el esquema BANQUETES_CATHERINE...
"!SQLPLUS!" -L / as sysdba @database/98_instalar_local_sysdba.sql > ".estado\instalacion_bd.log" 2>&1
if errorlevel 1 (
    echo [ERROR] SQLPlus reporto un error.
    echo [INFO] Ultimas lineas de .estado\instalacion_bd.log:
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content '.estado\instalacion_bd.log' -Tail 80"
    echo.
    echo [PISTA] Si aparece ORA-01031, abre esta terminal como administrador o agrega tu usuario al grupo ora_dba.
    echo [PISTA] Si aparece ORA-65011/XEPDB1/FREEPDB1, vuelve a ejecutar reinstalar_base_datos.bat; el script ya autodetecta el PDB.
    echo [PISTA] Si Oracle no esta iniciado, abre Servicios y arranca OracleServiceXE u OracleServiceFREE.
    pause
    exit /b 1
)

echo instalado > ".estado\bd_instalada.ok"
echo [OK] Base de datos reinstalada.
endlocal
