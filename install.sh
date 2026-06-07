#!/bin/bash
#
# install.sh — build (if needed) and install the screen saver for the current user.
#
set -euo pipefail
cd "$(dirname "$0")"

NAME="Flying Toasters"
SAVER="build/${NAME}.saver"
DEST="$HOME/Library/Screen Savers"

if [[ ! -d "$SAVER" ]]; then
  echo "==> No build found; building first"
  ./build.sh
fi

echo "==> Installing to $DEST"
mkdir -p "$DEST"
rm -rf "$DEST/${NAME}.saver"
cp -R "$SAVER" "$DEST/"

echo "==> Installed: $DEST/${NAME}.saver"
echo
echo "Open System Settings → Screen Saver and choose “Flying Toasters”."
echo "(If it was already selected, pick another saver and back again to reload.)"

# Best-effort: open the Screen Saver settings pane.
open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" 2>/dev/null \
  || open -b com.apple.systempreferences 2>/dev/null || true
