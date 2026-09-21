#!/bin/bash

# novooa Deployment CLI Launcher
# Konvenienz-Script zum Starten des Deployment-CLI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_DIR="$SCRIPT_DIR/cli"

if [ ! -f "$CLI_DIR/package.json" ]; then
  echo "❌ CLI nicht gefunden: $CLI_DIR"
  exit 1
fi

if [ ! -d "$CLI_DIR/node_modules" ]; then
  echo "📦 Dependencies werden installiert..."
  cd "$CLI_DIR"
  npm install --silent
  cd "$SCRIPT_DIR"
fi

if [ ! -d "$CLI_DIR/dist" ]; then
  echo "🔨 CLI wird gebaut..."
  cd "$CLI_DIR"
  npm run build --silent
  cd "$SCRIPT_DIR"
fi

echo "🚀 Starte novooa Deployment CLI..."
cd "$CLI_DIR"
node dist/index.js
