@echo off
setlocal enabledelayedexpansion

REM novooa Deployment CLI Launcher für Windows
REM Konvenienz-Script zum Starten des Deployment-CLI

for %%A in ("%cd%") do set "SCRIPT_DIR=%%~fA"
set "CLI_DIR=%SCRIPT_DIR%\cli"

if not exist "%CLI_DIR%\package.json" (
  echo ❌ CLI nicht gefunden: %CLI_DIR%
  pause
  exit /b 1
)

if not exist "%CLI_DIR%\node_modules" (
  echo 📦 Dependencies werden installiert...
  cd /d "%CLI_DIR%"
  call npm install --silent
  cd /d "%SCRIPT_DIR%"
)

if not exist "%CLI_DIR%\dist" (
  echo 🔨 CLI wird gebaut...
  cd /d "%CLI_DIR%"
  call npm run build --silent
  cd /d "%SCRIPT_DIR%"
)

echo 🚀 Starte novooa Deployment CLI...
cd /d "%CLI_DIR%"
node dist/index.js
pause
