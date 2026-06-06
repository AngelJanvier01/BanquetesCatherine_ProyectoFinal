@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

echo ============================================================
echo  Instalacion facil - Banquetes Catherine
echo ============================================================
echo.
echo Este instalador:
echo  - Crea/actualiza .venv
echo  - Instala dependencias Python
echo  - Configura .env para Oracle XE local
echo  - Crea/reinstala SOLO el esquema BANQUETES_CATHERINE
echo.

if not exist ".estado" mkdir ".estado"

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

echo [INFO] Cerrando servidores anteriores del proyecto...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$raiz=(Get-Location).Path; Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'python*.exe' -and $_.CommandLine -like ('*' + $raiz + '*aplicacion*app.py*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

echo [INFO] Creando entorno virtual...
%PYTHON% -m venv .venv
if errorlevel 1 (
    echo [ERROR] No se pudo crear el entorno virtual.
    pause
    exit /b 1
)

echo [INFO] Actualizando pip...
".venv\Scripts\python.exe" -m pip install --upgrade pip > ".estado\pip.log"

echo [INFO] Instalando dependencias Python...
".venv\Scripts\python.exe" -m pip install -r aplicacion\requirements.txt >> ".estado\pip.log"
if errorlevel 1 (
    echo [ERROR] No se pudieron instalar dependencias Python.
    echo [INFO] Revisa el detalle en .estado\pip.log
    pause
    exit /b 1
)

echo [INFO] Escribiendo configuracion .env...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$contenido=@('ORACLE_HOST=127.0.0.1','ORACLE_PORT=1521','ORACLE_SERVICE=AUTO','ORACLE_USER=BANQUETES_CATHERINE','ORACLE_PASSWORD=Catherine2026','ORACLE_USAR_SYSDBA_LOCAL=S','ORACLE_CLIENT_LIB_DIR=AUTO','','FLASK_HOST=127.0.0.1','FLASK_PORT=5000','FLASK_SECRET_KEY=banquetes-catherine-demo'); Set-Content -Path '.env' -Value $contenido -Encoding ASCII"

set "SQLPLUS=sqlplus"
where sqlplus >nul 2>nul
if errorlevel 1 (
    echo [INFO] SQLPlus no esta en PATH. Buscando en C:\app...
    for /f "delims=" %%S in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path 'C:\app' -Recurse -Filter sqlplus.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName"') do set "SQLPLUS=%%S"
    if not exist "!SQLPLUS!" (
        echo [ERROR] No se encontro SQLPlus. Revisa que Oracle XE o Oracle Free este instalado.
        echo         Tambien puedes abrir SQL Developer y ejecutar database\98_instalar_local_sysdba.sql como SYS.
        pause
        exit /b 1
    )
)

echo [INFO] Instalando base de datos por conexion local SYSDBA...
"%SQLPLUS%" -L / as sysdba @database/98_instalar_local_sysdba.sql > ".estado\instalacion_bd.log" 2>&1
if errorlevel 1 (
    echo [ERROR] SQLPlus reporto un error instalando la base.
    echo [INFO] Ultimas lineas de .estado\instalacion_bd.log:
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content '.estado\instalacion_bd.log' -Tail 80"
    echo.
    echo [PISTA] Si aparece ORA-01031, abre esta terminal como administrador o agrega tu usuario al grupo ora_dba.
    echo [PISTA] Si aparece ORA-65011/XEPDB1/FREEPDB1, vuelve a ejecutar instalar.bat; el script ya autodetecta el PDB.
    echo [PISTA] Si Oracle no esta iniciado, abre Servicios y arranca OracleServiceXE u OracleServiceFREE.
    pause
    exit /b 1
)

echo instalado > ".estado\bd_instalada.ok"

echo.
echo [OK] Instalacion completada.
echo Usuarios demo:
echo   admin.catherine / admin123
echo   gerente.lucia   / gerente123
echo   cliente.demo    / cliente123
echo   chef.renata     / gerente123
echo.
echo Ejecuta abrir_proyecto.bat para abrir el sistema.
endlocal
