@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if exist ".run\servidor.pid" (
    for /f %%P in (.run\servidor.pid) do set "PID=%%P"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Process -Id %PID% -ErrorAction SilentlyContinue) { Stop-Process -Id %PID% -Force; Write-Host '[OK] Servicio detenido por PID %PID%' }"
    del ".run\servidor.pid" >nul 2>nul
    goto fin
)

if exist ".run\puerto.txt" (
    for /f %%P in (.run\puerto.txt) do set "PUERTO=%%P"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=Get-NetTCPConnection -LocalPort %PUERTO% -ErrorAction SilentlyContinue | Select-Object -First 1; if($c){ Stop-Process -Id $c.OwningProcess -Force; Write-Host '[OK] Servicio detenido por puerto %PUERTO%' } else { Write-Host '[INFO] No habia servicio escuchando en el puerto %PUERTO%' }"
    goto fin
)

echo [INFO] No se encontro PID ni puerto del servicio.

:fin
if exist ".run\puerto.txt" del ".run\puerto.txt" >nul 2>nul
endlocal

