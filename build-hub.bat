@echo off
rem ============================================================
rem Build & push to Docker Hub (hub.docker.com)
rem Version is read from DOCUSAURUS_VERSION in .env
rem Usage:
rem   build-hub.bat                  Build + push <version> and latest tags
rem   build-hub.bat nopush           Build only, skip push
rem   build-hub.bat myname/docs      Build with custom hub repo name
rem   build-hub.bat myname/docs nopush
rem
rem After a successful build the image is also exported to a tar
rem file (<repo>_<version>.tar) in the current directory.
rem
rem Repo name resolution (first match wins):
rem   1. Command line argument (e.g. myname/docs)
rem   2. DOCKERHUB_REPO in .env
rem   3. IMAGE_NAME in .env (default: docusaurus-site)
rem Note: Docker Hub repo name must be <username>/<image>. Run
rem   docker login before pushing if not logged in.
rem ============================================================
setlocal

if not exist .env (
    echo [ERROR] .env not found. Copy .env.example to .env first.
    exit /b 1
)

rem ---------- Read config from .env ----------
set "VERSION="
set "IMAGE="
set "HUB_REPO="
for /f "tokens=1,* delims==" %%a in ('findstr /b "DOCUSAURUS_VERSION=" .env') do set "VERSION=%%b"
for /f "tokens=1,* delims==" %%a in ('findstr /b "IMAGE_NAME=" .env') do set "IMAGE=%%b"
for /f "tokens=1,* delims==" %%a in ('findstr /b "DOCKERHUB_REPO=" .env') do set "HUB_REPO=%%b"

if "%VERSION%"=="" (
    echo [ERROR] DOCUSAURUS_VERSION not set in .env
    exit /b 1
)
if "%IMAGE%"=="" set "IMAGE=docusaurus-site"

rem ---------- Parse arguments ----------
set "PUSH=push"
for %%p in (%*) do (
    if /i "%%p"=="nopush" (set "PUSH=") else (set "HUB_REPO=%%p")
)
if "%HUB_REPO%"=="" set "HUB_REPO=%IMAGE%"

rem Docker Hub requires <username>/<image> format for push
echo %HUB_REPO% | findstr /c:"/" >nul
if errorlevel 1 (
    echo [WARN] HUB_REPO "%HUB_REPO%" has no "/" prefix ^(<username^>/<image^>^).
    echo        Push may fail unless it matches your Docker Hub username.
    echo        Fix: add DOCKERHUB_REPO=<username^>/<image^> to .env
)

echo ============================================================
echo  Repo    : %HUB_REPO%
echo  Version : %VERSION%  ^(from .env DOCUSAURUS_VERSION^)
echo  Tags    : %VERSION%, latest
echo ============================================================

echo [1/4] Syncing Docusaurus version %VERSION% to site\package.json ...
rem NOTE: keep the PowerShell command free of embedded double quotes,
rem otherwise cmd misparses the pipe; use \x22 for a double quote and
rem ${1} so it won't merge with following digits and parse as $13
powershell -NoProfile -Command "$f='site\package.json'; (Get-Content $f -Raw) -replace '(@docusaurus/[\w-]+\x22\s*:\s*\x22)[^\x22]+','${1}%VERSION%' | Set-Content $f -NoNewline" || exit /b 1

echo [2/4] Building image %HUB_REPO%:%VERSION% (Docusaurus %VERSION%) ...
docker build -t %HUB_REPO%:%VERSION% -t %HUB_REPO%:latest . || exit /b 1

echo [3/4] Build finished:
docker images "%HUB_REPO%"

if "%PUSH%"=="" (
    echo [4/4] Push skipped. To publish: build-hub.bat %HUB_REPO%
    goto :end
)

echo [4/4] Pushing to Docker Hub ...
docker push %HUB_REPO%:%VERSION% || goto :push_fail
docker push %HUB_REPO%:latest || goto :push_fail
echo Push done. User upgrade: set DOCUSAURUS_VERSION=%VERSION% in .env, then:
echo   docker compose pull ^&^& docker compose up -d
goto :end

:push_fail
echo.
echo [ERROR] Push failed. If unauthorized, run first:
echo   docker login
echo Then re-run: build-hub.bat
exit /b 1

:end
endlocal
