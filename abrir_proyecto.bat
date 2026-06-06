@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [INFO] No existe entorno virtual. Ejecutando instalacion facil...
    call instalar.bat
)

if not exist ".estado\bd_instalada.ok" (
    echo [INFO] No se encontro marca de base instalada. Ejecutando instalacion facil...
    call instalar.bat
)

call iniciar.bat
endlocal

