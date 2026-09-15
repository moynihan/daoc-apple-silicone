#!/bin/zsh
# Launch Dark Age of Camelot under Wine. Runs the official patcher first
# (it self-updates, patches the game, then shows the Play button).
set -e
cd "$(dirname "$0")"
. ./env.sh
GAME="$WINEPREFIX/drive_c/Program Files (x86)/Electronic Arts/Dark Age of Camelot"
cd "$GAME"
exec wine camelot.exe "$@"
