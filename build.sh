#!/bin/bash
#
# build.sh — compile the Flying Toasters screen saver into a .saver bundle.
#
# Produces:  build/Flying Toasters.saver
# Options:   UNIVERSAL=1 ./build.sh   # build a universal arm64 + x86_64 binary
#
set -euo pipefail
cd "$(dirname "$0")"

NAME="Flying Toasters"
MODULE="FlyingToasters"
EXEC="FlyingToasters"
DEPLOY="11.0"

SAVER="build/${NAME}.saver"
CONTENTS="${SAVER}/Contents"
MACOS="${CONTENTS}/MacOS"
RES="${CONTENTS}/Resources"

SOURCES=(
  src/Sprites.swift
  src/ToasterArt.swift
  src/ToasterScene.swift
  src/ToasterSettings.swift
  src/Defaults.swift
  src/ConfigureSheet.swift
  src/FlyingToastersView.swift
)

echo "==> Cleaning"
rm -rf "$SAVER"
mkdir -p "$MACOS" "$RES"

COMMON_FLAGS=(
  -O -wmo
  -module-name "$MODULE"
  -Xlinker -bundle           # produce a proper Mach-O loadable bundle (MH_BUNDLE)
  -framework ScreenSaver -framework AppKit -framework QuartzCore
)

if [[ "${UNIVERSAL:-0}" == "1" ]]; then
  echo "==> Compiling (universal arm64 + x86_64)"
  swiftc "${COMMON_FLAGS[@]}" -target "arm64-apple-macos${DEPLOY}"  -o "build/${EXEC}-arm64"  "${SOURCES[@]}"
  swiftc "${COMMON_FLAGS[@]}" -target "x86_64-apple-macos${DEPLOY}" -o "build/${EXEC}-x86_64" "${SOURCES[@]}"
  lipo -create "build/${EXEC}-arm64" "build/${EXEC}-x86_64" -output "${MACOS}/${EXEC}"
  rm -f "build/${EXEC}-arm64" "build/${EXEC}-x86_64"
else
  ARCH="$(uname -m)"
  echo "==> Compiling (${ARCH})"
  swiftc "${COMMON_FLAGS[@]}" -target "${ARCH}-apple-macos${DEPLOY}" -o "${MACOS}/${EXEC}" "${SOURCES[@]}"
fi

echo "==> Assembling bundle"
cp Info.plist "${CONTENTS}/Info.plist"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$SAVER" >/dev/null 2>&1 || echo "   (codesign skipped)"

echo "==> Done: $SAVER"
file "${MACOS}/${EXEC}"
echo
echo "Install with:  ./install.sh        (copies to ~/Library/Screen Savers)"
echo "Preview with:  ./preview.sh        (runs a live window, no install needed)"
