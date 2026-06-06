@echo off
setlocal EnableExtensions
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] No existe .venv. Ejecuta instalar.bat primero.
    exit /b 1
)

if not exist ".run" mkdir ".run"

for /f %%P in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=5000; while((Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue)){ $p++ }; $p"') do set "PUERTO=%%P"

echo %PUERTO% > ".run\puerto.txt"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$raiz=(Get-Location).Path; $puerto='%PUERTO%'; $env:FLASK_PORT=$puerto; $env:FLASK_HOST='127.0.0.1'; $log=Join-Path $raiz '.run\servidor.log'; $err=Join-Path $raiz '.run\servidor.err'; $p=Start-Process -FilePath (Join-Path $raiz '.venv\Scripts\python.exe') -ArgumentList (Join-Path $raiz 'aplicacion\app.py') -WorkingDirectory $raiz -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru; $p.Id | Set-Content (Join-Path $raiz '.run\servidor.pid')"

timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:%PUERTO%"

echo [OK] Servicio iniciado en http://127.0.0.1:%PUERTO%
echo [INFO] Log: .run\servidor.log
endlocal

