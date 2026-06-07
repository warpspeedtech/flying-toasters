#!/bin/bash
#
# build-app.sh — build the standalone "Flying Toasters.app" (live player + settings).
# Its Options button writes to the same preferences the installed .saver reads, so it's
# the reliable way to configure the saver (the System Settings Options button is buggy
# on modern macOS).
#
set -euo pipefail
cd "$(dirname "$0")"

NAME="Flying Toasters"
EXEC="FlyingToasters"
DEPLOY="11.0"

APP="build/${NAME}.app"
CONTENTS="${APP}/Contents"
MACOS="${CONTENTS}/MacOS"

SOURCES=(
  tools/preview_main.swift
  src/Sprites.swift
  src/ToasterArt.swift
  src/ToasterScene.swift
  src/ToasterSettings.swift
  src/Defaults.swift
  src/ConfigureSheet.swift
  src/FlyingToastersView.swift
)

echo "==> Cleaning"
rm -rf "$APP"
mkdir -p "$MACOS"

ARCH="$(uname -m)"
echo "==> Compiling app (${ARCH})"
swiftc -O \
  -module-name FTApp \
  -target "${ARCH}-apple-macos${DEPLOY}" \
  -framework AppKit -framework ScreenSaver -framework QuartzCore \
  -o "${MACOS}/${EXEC}" \
  "${SOURCES[@]}"

echo "==> Assembling bundle"
cp App-Info.plist "${CONTENTS}/Info.plist"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || echo "   (codesign skipped)"

echo "==> Done: $APP"
echo "Run it:   open \"$APP\""
