@echo off
title Subir Optimiza Laptop a GitHub
cd /d "%~dp0"
set "PATH=C:\Users\Usuario\AppData\Local\Programs\gh;C:\Users\Usuario\AppData\Local\Programs\MinGit\cmd;%PATH%"

echo =======================================================
echo     Subir Suite "optimiza-laptop" a tu cuenta de GitHub
echo =======================================================
echo.


gh auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] No has iniciado sesion en GitHub en este equipo.
    echo [*] Se abrira tu navegador Edge con un codigo seguro.
    echo.
    gh auth login -w -p https
)

echo.
echo [*] Creando repositorio remoto y subiendo archivos a GitHub...
gh repo create optimiza-laptop --public --source=. --remote=origin --push

if %errorlevel% equ 0 (
    echo.
    echo =======================================================
    echo  [+] Repositorio creado y subido con exito a tu GitHub!
    echo =======================================================
) else (
    echo.
    echo [*] Si el repositorio ya existia en tu cuenta, sincronizando:
    git push -u origin main
)

echo.
pause
