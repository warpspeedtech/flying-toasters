#!/bin/bash
#
# preview.sh — build and run a live preview window of the screen saver,
# no installation required. ⌘, for Options · ⌘F full screen · Esc / ⌘Q to quit.
#
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build

echo "==> Building preview app"
swiftc -O \
  -module-name FTPreview \
  -framework AppKit -framework ScreenSaver -framework QuartzCore \
  tools/preview_main.swift \
  src/Sprites.swift src/ToasterArt.swift src/ToasterScene.swift src/ToasterSettings.swift \
  src/Defaults.swift src/ConfigureSheet.swift src/FlyingToastersView.swift \
  -o build/FlyingToastersPreview

echo "==> Launching (Esc or ⌘Q to quit)"
exec build/FlyingToastersPreview
