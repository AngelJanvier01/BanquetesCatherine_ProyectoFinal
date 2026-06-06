@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

if exist ".estado\servidor.pid" (
    for /f %%P in (.estado\servidor.pid) do set "PID=%%P"
    if not "!PID!"=="" (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-Process -Id !PID! -ErrorAction SilentlyContinue) { Stop-Process -Id !PID! -Force; Write-Host '[OK] Servicio detenido por PID !PID!' } else { Write-Host '[INFO] No habia proceso con PID !PID!' }"
    )
    del ".estado\servidor.pid" >nul 2>nul
)

if exist ".estado\puerto.txt" (
    for /f %%P in (.estado\puerto.txt) do set "PUERTO=%%P"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=Get-NetTCPConnection -LocalPort !PUERTO! -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.OwningProcess -gt 0 } | Select-Object -First 1; if($c){ Stop-Process -Id $c.OwningProcess -Force; Write-Host '[OK] Servicio detenido por puerto !PUERTO!' } else { Write-Host '[INFO] No habia servicio escuchando en el puerto !PUERTO!' }"
    goto fin
)

echo [INFO] No se encontro PID ni puerto del servicio.

:fin
if exist ".estado\puerto.txt" del ".estado\puerto.txt" >nul 2>nul
endlocal
