#!/bin/bash
#
# uninstall.sh — remove the installed screen saver for the current user.
#
set -euo pipefail
NAME="Flying Toasters"
TARGET="$HOME/Library/Screen Savers/${NAME}.saver"

if [[ -d "$TARGET" ]]; then
  rm -rf "$TARGET"
  echo "Removed $TARGET"
else
  echo "Nothing to remove at $TARGET"
fi
