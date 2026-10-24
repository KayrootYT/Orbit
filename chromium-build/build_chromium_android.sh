#!/usr/bin/env bash
set -euo pipefail

# Build upstream Chromium for Android ARM64.
# This produces Chromium's ChromePublic.apk, not a branded Orbit browser APK.

CHROMIUM_ROOT="${ORBIT_CHROMIUM_ROOT:-$HOME/orbit-chromium/src}"
CHROMIUM_PARENT="$(dirname "$CHROMIUM_ROOT")"
DEPOT_TOOLS_DIR="${DEPOT_TOOLS_DIR:-$HOME/depot_tools}"
OUT_DIR="out/Orbit"

mkdir -p "$CHROMIUM_PARENT"

if [ ! -x "$DEPOT_TOOLS_DIR/fetch" ]; then
  echo "Installing depot_tools..."
  if [ -d "$DEPOT_TOOLS_DIR/.git" ]; then
    git -C "$DEPOT_TOOLS_DIR" pull --ff-only
  else
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "$DEPOT_TOOLS_DIR"
  fi
fi

export PATH="$DEPOT_TOOLS_DIR:$PATH"
export DEPOT_TOOLS_UPDATE=0

if [ ! -d "$CHROMIUM_ROOT/.git" ]; then
  if [ -e "$CHROMIUM_ROOT" ]; then
    echo "::error::Chromium root exists but is not a Git checkout: $CHROMIUM_ROOT"
    exit 1
  fi
  cd "$CHROMIUM_PARENT"
  fetch --nohooks --no-history android
fi

if [ ! -d "$CHROMIUM_ROOT/.git" ]; then
  echo "::error::Chromium checkout not found at $CHROMIUM_ROOT"
  exit 1
fi

cd "$CHROMIUM_ROOT"

echo "Installing Chromium build dependencies..."
if [ -x build/install-build-deps.sh ]; then
  if [ "$(id -u)" -eq 0 ]; then
    ./build/install-build-deps.sh --no-prompt
  elif command -v sudo >/dev/null 2>&1; then
    sudo ./build/install-build-deps.sh --no-prompt
  else
    echo "::error::Build dependency installation needs root or sudo."
    exit 1
  fi
fi

echo "Syncing Chromium hooks..."
gclient runhooks

echo "Generating ARM64 release build configuration..."
gn gen "$OUT_DIR" --args='target_os="android" target_cpu="arm64" is_debug=false is_component_build=false symbol_level=1'

echo "Building Chromium public APK..."
autoninja -C "$OUT_DIR" chrome_public_apk

APK_PATH="$OUT_DIR/apks/ChromePublic.apk"
if [ ! -s "$APK_PATH" ]; then
  echo "::error::Build finished but APK is missing: $APK_PATH"
  find "$OUT_DIR" -type f -name '*.apk' -print || true
  exit 1
fi

echo "Chromium APK built successfully:"
ls -lh "$APK_PATH"
sha256sum "$APK_PATH"
