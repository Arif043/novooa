#!/bin/bash
set -euo pipefail

# Baut die novooa Runtime- und ML-Sidecar-Images für linux/amd64 (Windows-
# Zielplattform) direkt auf diesem Rechner. Läuft eigenständig, ohne SSH und
# ohne die Deployment-CLI - nutzt Docker Buildx, um auch von einem
# Apple-Silicon-Mac (arm64) aus amd64-Images zu erzeugen (Cross-Compile per
# QEMU-Emulation über den Buildx-Builder).
#
# Ergebnis ist eine einzelne .tar-Datei mit beiden Images, die auf jedem
# Docker-Host ohne Registry-Zugriff eingespielt werden kann:
#   docker load -i novooa-images-<version>.tar

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "Verwendung: $0 <version>" >&2
  echo "Beispiel:   $0 0.1.0" >&2
  exit 1
fi

if ! [[ "$VERSION" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  echo "Ungültige Version: '$VERSION' (nur Buchstaben, Ziffern, Punkt, Bindestrich, Unterstrich)" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/build"
PLATFORM="linux/amd64"

RUNTIME_IMAGE="novooa-runtime:${VERSION}"
ML_IMAGE="novooa-ml:${VERSION}"
SCRIPT_IMAGE="novooa-script:${VERSION}"
PACKAGES_IMAGE="novooa-packages:${VERSION}"
OUTPUT_TAR="$OUTPUT_DIR/novooa-images-${VERSION}.tar"

mkdir -p "$OUTPUT_DIR"

echo "==> Baue ${RUNTIME_IMAGE} (${PLATFORM})"
docker buildx build \
  --platform "$PLATFORM" \
  -f "$REPO_ROOT/functions/Dockerfile.local-runtime" \
  -t "$RUNTIME_IMAGE" \
  --load \
  "$REPO_ROOT"

echo "==> Baue ${ML_IMAGE} (${PLATFORM})"
docker buildx build \
  --platform "$PLATFORM" \
  -f "$REPO_ROOT/functions/Dockerfile.model-inference-sidecar" \
  -t "$ML_IMAGE" \
  --load \
  "$REPO_ROOT"

echo "==> Baue ${SCRIPT_IMAGE} (${PLATFORM})"
docker buildx build \
  --platform "$PLATFORM" \
  -f "$REPO_ROOT/functions/Dockerfile.script-runner" \
  -t "$SCRIPT_IMAGE" \
  --load \
  "$REPO_ROOT"

echo "==> Baue ${PACKAGES_IMAGE} (${PLATFORM})"
docker buildx build \
  --platform "$PLATFORM" \
  -f "$REPO_ROOT/functions/Dockerfile.script-packages" \
  -t "$PACKAGES_IMAGE" \
  --load \
  "$REPO_ROOT"

echo "==> Exportiere Images nach ${OUTPUT_TAR}"
docker save "$RUNTIME_IMAGE" "$ML_IMAGE" "$SCRIPT_IMAGE" "$PACKAGES_IMAGE" -o "$OUTPUT_TAR"

echo ""
echo "Fertig."
echo "  Images:  $RUNTIME_IMAGE, $ML_IMAGE, $SCRIPT_IMAGE, $PACKAGES_IMAGE (linux/${PLATFORM#linux/})"
echo "  Archiv:  $OUTPUT_TAR"
echo ""
echo "Auf dem Ziel-Windows-Rechner einspielen:"
echo "  docker load -i novooa-images-${VERSION}.tar"
echo "  docker compose -f docker-compose.local.yaml up --detach   # falls image: statt build: referenziert wird"
