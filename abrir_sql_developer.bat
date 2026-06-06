@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "SQLDEV="

if exist "C:\sqldeveloper-24.3.1.347.1826-x64\sqldeveloper\sqldeveloper.exe" (
    set "SQLDEV=C:\sqldeveloper-24.3.1.347.1826-x64\sqldeveloper\sqldeveloper.exe"
)

if not defined SQLDEV (
    for /f "delims=" %%R in ('dir /b /s "C:\sqldeveloper.exe" "C:\sqldeveloper*\sqldeveloper\sqldeveloper.exe" "C:\Program Files\sqldeveloper*\sqldeveloper.exe" 2^>nul') do (
        if not defined SQLDEV set "SQLDEV=%%R"
    )
)

if not defined SQLDEV (
    echo [ERROR] No encontre SQL Developer instalado.
    echo.
    echo Instala con winget:
    echo winget install --id Oracle.SQLDeveloper -e
    echo.
    pause
    exit /b 1
)

echo ============================================================
echo  SQL Developer - Banquetes Catherine
echo ============================================================
echo.
echo [INFO] Preparando modo compartido para SQL Developer...
sqlplus -S / as sysdba @database\99_preparar_sql_developer.sql
echo.
echo Conexion recomendada para crear en SQL Developer:
echo.
echo   Name:          Banquetes Catherine
echo   Username:      BANQUETES_CATHERINE
echo   Password:      Catherine2026
echo.
echo   Connection Type: Advanced
echo   Custom JDBC URL:
echo   jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=SHARED)(SERVICE_NAME=xepdb1)))
echo.
echo IMPORTANTE:
echo   En esta maquina la conexion Basic falla por ORA-12518.
echo   Usa Advanced con el URL de arriba. Boton Test debe marcar Success.
echo.
echo Archivo maestro para abrir:
echo   %cd%\ProyectoFinal_BanquetesCatherine_SQLDeveloper.sql
echo.

start "" "%SQLDEV%" "%cd%\ProyectoFinal_BanquetesCatherine_SQLDeveloper.sql"
pause
