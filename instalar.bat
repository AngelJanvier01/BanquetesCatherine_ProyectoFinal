@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

echo ============================================================
echo  Instalador Banquetes Catherine
echo ============================================================

where py >nul 2>nul
if errorlevel 1 (
    where python >nul 2>nul
    if errorlevel 1 (
        echo [INFO] Python no fue encontrado. Se intentara instalar con winget.
        winget install --id Python.Python.3.12 -e --accept-package-agreements --accept-source-agreements
    )
)

where py >nul 2>nul
if errorlevel 1 (
    set "PYTHON=python"
) else (
    set "PYTHON=py -3"
)

echo [INFO] Creando entorno virtual...
%PYTHON% -m venv .venv
if errorlevel 1 (
    echo [ERROR] No se pudo crear el entorno virtual.
    exit /b 1
)

echo [INFO] Actualizando pip...
".venv\Scripts\python.exe" -m pip install --upgrade pip

echo [INFO] Instalando dependencias Python...
".venv\Scripts\python.exe" -m pip install -r aplicacion\requirements.txt
if errorlevel 1 (
    echo [ERROR] No se pudieron instalar dependencias.
    exit /b 1
)

if not exist ".env" (
    copy ".env.example" ".env" >nul
    echo [OK] Se creo .env desde .env.example
) else (
    echo [OK] .env ya existe
)

where sqlplus >nul 2>nul
if errorlevel 1 (
    where sql >nul 2>nul
    if errorlevel 1 (
        echo [INFO] No se encontro SQLPlus ni SQLcl. Se intentara instalar SQLcl con winget.
        winget install --id Oracle.SQLcl -e --accept-package-agreements --accept-source-agreements
        set "CLIENTE_SQL=sql"
    ) else (
        set "CLIENTE_SQL=sql"
    )
) else (
    set "CLIENTE_SQL=sqlplus"
)

if /I "%CLIENTE_SQL%"=="sqlplus" (
    echo [OK] SQLPlus detectado
) else (
    echo [OK] SQLcl detectado
)

set /p EJECUTAR_SQL="Deseas ejecutar scripts Oracle ahora? (S/N): "
if /I not "%EJECUTAR_SQL%"=="S" goto fin

echo.
echo Se instalaran objetos dentro del esquema BANQUETES_CATHERINE.
echo No se eliminan usuarios ni bases de datos externas.
echo.
where %CLIENTE_SQL% >nul 2>nul
if errorlevel 1 (
    echo [ERROR] No hay cliente Oracle disponible en PATH. Ejecuta el SQL manualmente en SQL Developer.
    goto fin
)

set /p CREAR_USUARIO="Deseas crear el usuario BANQUETES_CATHERINE con una conexion admin? (S/N): "
if /I "%CREAR_USUARIO%"=="S" (
    set /p CONEXION_ADMIN="Conexion admin (ejemplo sys/TuClave@//127.0.0.1:1521/XEPDB1 as sysdba): "
    pushd database
    %CLIENTE_SQL% -L "%CONEXION_ADMIN%" @01_crear_usuario_opcional.sql
    popd
)

echo.
set /p CONEXION_APP="Conexion del esquema (ejemplo BANQUETES_CATHERINE/Catherine2026@//127.0.0.1:1521/XEPDB1): "

pushd database
%CLIENTE_SQL% -L "%CONEXION_APP%" @99_instalar_todo.sql
popd

:fin
echo.
echo [OK] Instalacion local terminada.
echo Ejecuta iniciar.bat para abrir el sistema.
endlocal
