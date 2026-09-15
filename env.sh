# Source this: . ./env.sh
export DAOC_ROOT="${0:A:h}"   # folder containing this file (zsh)
export WINE="$DAOC_ROOT/wine/Wine Stable.app/Contents/Resources/wine/bin/wine"
export WINESERVER="$DAOC_ROOT/wine/Wine Stable.app/Contents/Resources/wine/bin/wineserver"
export WINEPREFIX="$DAOC_ROOT/prefix"
export WINEDEBUG=-all
export PATH="$DAOC_ROOT/wine/Wine Stable.app/Contents/Resources/wine/bin:$PATH"
