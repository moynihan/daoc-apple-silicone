#!/bin/zsh
# Dark Age of Camelot installer for Apple Silicon Macs.
# Double-click this file. It sets up everything needed to play DAoC on a Mac:
#   1. Rosetta 2 (Apple's Intel translator, needed by Wine)
#   2. Wine 11 (runs Windows programs), installed privately under
#      ~/Applications/Dark Age of Camelot/  -- nothing system-wide is touched
#   3. The official DAoC patcher, which downloads the game (~4.5 GB)
#   4. A "Dark Age of Camelot" app in ~/Applications you double-click to play
#
# Re-running this script is safe: finished steps are skipped.

set -u
setopt NULL_GLOB

WINE_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.0_1/wine-stable-11.0_1-osx64.tar.xz"
WINE_SHA256="b50dc50ec7f41d58b115a6b685d4d1315ba3c797bd3aa0f49213f2703cb82388"

BASE="${DAOC_HOME:-$HOME/Applications/Dark Age of Camelot}"
WINE_DIR="$BASE/wine"
export WINEPREFIX="$BASE/prefix"
export WINEDEBUG=-all
export WINEDLLOVERRIDES="winemenubuilder.exe=d"   # don't spam ~/Applications with Wine shortcuts
PAYLOAD="$(cd "$(dirname "$0")" && pwd)/payload"
GAME="$WINEPREFIX/drive_c/Program Files (x86)/Electronic Arts/Dark Age of Camelot"
APP="${DAOC_APP:-$HOME/Applications/Dark Age of Camelot.app}"
LOG="$BASE/install.log"

say()  { print -P "%F{cyan}==>%f $*"; }
ok()   { print -P "%F{green}  ✓%f $*"; }
die()  { print -P "%F{red}ERROR:%f $*"; echo; echo "Details are in: $LOG"; echo "Press Return to close."; read -r; exit 1; }

mkdir -p "$BASE" || die "Cannot create $BASE"
exec > >(tee -a "$LOG") 2>&1
echo; echo "Dark Age of Camelot for Mac — installer  ($(date))"; echo

# ---------------------------------------------------------------- checks
[[ "$(uname -m)" == "arm64" ]] || die "This installer is for Apple Silicon Macs (M1/M2/M3/M4)."
osver=$(sw_vers -productVersion); major=${osver%%.*}
(( major >= 13 )) || die "macOS 13 or newer is required (you have $osver)."
ok "Apple Silicon Mac running macOS $osver"

# ---------------------------------------------------------------- 1. Rosetta
if /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
  ok "Rosetta 2 already installed"
else
  say "Installing Rosetta 2 (Apple may ask for your password)..."
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license \
    || sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license \
    || die "Rosetta 2 install failed."
  ok "Rosetta 2 installed"
fi

# ---------------------------------------------------------------- 2. Wine
WINE_BIN="$WINE_DIR/Wine Stable.app/Contents/Resources/wine/bin"
if [[ -x "$WINE_BIN/wine" ]] && "$WINE_BIN/wine" --version >/dev/null 2>&1; then
  ok "Wine already installed ($("$WINE_BIN/wine" --version))"
else
  say "Downloading Wine (about 180 MB)..."
  tmp="$BASE/wine.tar.xz"
  curl -fL --progress-bar -o "$tmp" "$WINE_URL" || die "Wine download failed. Check your internet connection."
  if [[ "$WINE_SHA256" != __* ]]; then
    got=$(shasum -a 256 "$tmp" | cut -d' ' -f1)
    [[ "$got" == "$WINE_SHA256" ]] || die "Wine download is corrupted (checksum mismatch)."
  fi
  say "Unpacking Wine..."
  rm -rf "$WINE_DIR"; mkdir -p "$WINE_DIR"
  tar -xJf "$tmp" -C "$WINE_DIR" || die "Could not unpack Wine."
  rm -f "$tmp"
  xattr -dr com.apple.quarantine "$WINE_DIR" 2>/dev/null || true
  "$WINE_BIN/wine" --version >/dev/null 2>&1 || die "Wine does not start on this Mac."
  ok "Wine installed ($("$WINE_BIN/wine" --version))"
fi
export PATH="$WINE_BIN:$PATH"

# ---------------------------------------------------------------- 3. Wine prefix
if [[ -f "$WINEPREFIX/system.reg" ]]; then
  ok "Wine environment already prepared"
else
  say "Preparing the Wine environment (first time only, about a minute)..."
  wineboot -i >/dev/null 2>&1 || die "Could not initialise Wine."
  wine reg add 'HKCU\Software\Wine' /v Version /t REG_SZ /d win7 /f >/dev/null 2>&1
  wine reg add 'HKCU\Software\Wine\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f >/dev/null 2>&1
  wineserver -w
  ok "Wine environment ready"
fi

# ---------------------------------------------------------------- 4. Game files
if [[ -f "$GAME/camelot.exe" && -f "$GAME/patch.cfg" ]]; then
  ok "DAoC patcher already in place"
else
  [[ -f "$PAYLOAD/camelot.exe" && -f "$PAYLOAD/patch.cfg" ]] || die "The 'payload' folder is missing next to this installer."
  mkdir -p "$GAME" && cp "$PAYLOAD/camelot.exe" "$PAYLOAD/patch.cfg" "$GAME/" || die "Could not copy the patcher."
  ok "DAoC patcher installed"
fi

# ---------------------------------------------------------------- 5. Launcher app
say "Creating the 'Dark Age of Camelot' app in ~/Applications..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Dark Age of Camelot</string>
  <key>CFBundleDisplayName</key><string>Dark Age of Camelot</string>
  <key>CFBundleIdentifier</key><string>local.daoc.launcher</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleExecutable</key><string>launch</string>
  <key>CFBundleIconFile</key><string>daoc.icns</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
PLIST
cat > "$APP/Contents/MacOS/launch" <<LAUNCH
#!/bin/zsh
# Starts the DAoC patcher; press Play in it once it says 100%.
export WINEPREFIX="$WINEPREFIX"
export WINEDEBUG=-all
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
export PATH="$WINE_BIN:\$PATH"
cd "$GAME" || exit 1
LOG="$BASE/wine.log"
: > "\$LOG"
exec wine camelot.exe >> "\$LOG" 2>&1
LAUNCH
chmod +x "$APP/Contents/MacOS/launch"
[[ -f "$PAYLOAD/daoc.icns" ]] && cp "$PAYLOAD/daoc.icns" "$APP/Contents/Resources/daoc.icns"
touch "$APP"
ok "App created: $APP"

# ---------------------------------------------------------------- 6. Patch
echo
say "Starting the DAoC patcher. It downloads the game (about 4.5 GB) —"
say "leave it alone until the top-left corner says 100%%, then press Play."
say "If the game quits the first time you press Play, open it again — the second launch works."
say "After that, just open 'Dark Age of Camelot' from ~/Applications to play."
echo
if [[ -z "${DAOC_NO_LAUNCH:-}" ]]; then
  open "$APP"
fi
echo "Done. You can close this window."
