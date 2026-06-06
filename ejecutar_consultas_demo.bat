@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

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

if not exist ".estado" mkdir ".estado"

echo [INFO] Ejecutando consultas preparadas para exposicion...
"!SQLPLUS!" -L / as sysdba @database/96_ejecutar_consultas_demo.sql > ".estado\consultas_demo.log" 2>&1
type ".estado\consultas_demo.log"
echo.
echo [OK] Resultado guardado en .estado\consultas_demo.log
pause
endlocal
