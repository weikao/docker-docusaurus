@echo off
rem ============================================================
rem Build Docusaurus production image (CN mirrors by default)
rem Usage:
rem   build.bat <version> [image-name] [push]
rem Examples:
rem   build.bat 3.10.2
rem   build.bat 3.10.2 registry.example.com/docs-site push
rem ============================================================
setlocal

if "%~1"=="" (
    echo Usage: build.bat ^<version^> [image-name] [push]
    echo Example: build.bat 3.10.2
    exit /b 1
)

set "VERSION=%~1"
if "%~2"=="" (set "IMAGE=docusaurus-site") else (set "IMAGE=%~2")
set "PUSH=%~3"

echo [1/4] Sync Docusaurus version %VERSION% to site\package.json ...
rem NOTE: keep the PowerShell command free of embedded double quotes,
rem otherwise cmd misparses the pipe; use \x22 for a double quote
powershell -NoProfile -Command "$f='site\package.json'; (Get-Content $f -Raw) -replace '(@docusaurus/[\w-]+\x22\s*:\s*\x22)[^\x22]+','${1}%VERSION%' | Set-Content $f -NoNewline" || exit /b 1

echo [2/4] Building image %IMAGE%:%VERSION% (Docusaurus %VERSION%) ...
docker build -t %IMAGE%:%VERSION% -t %IMAGE%:latest . || exit /b 1

echo [3/4] Build finished:
docker images %IMAGE%

if /i "%PUSH%"=="push" (
    echo [4/4] Pushing image to registry ...
    docker push %IMAGE%:%VERSION% || exit /b 1
    docker push %IMAGE%:latest || exit /b 1
    echo Push done. User upgrade: docker compose pull ^&^& docker compose up -d
) else (
    echo [4/4] Push skipped. To publish: build.bat %VERSION% %IMAGE% push
)

endlocal
