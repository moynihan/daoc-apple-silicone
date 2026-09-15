#!/bin/zsh
# Dark Age of Camelot installer for Apple Silicon Macs.
#
# Run it either way:
#   curl -fsSL https://raw.githubusercontent.com/moynihan/daoc-apple-silicone/main/install.sh | zsh
# or double-click "Install DAoC.command" from the downloaded zip.
#
# It sets up everything needed to play DAoC on a Mac:
#   1. Rosetta 2 (Apple's Intel translator, needed by Wine)
#   2. Wine 11 (runs Windows programs), installed privately under
#      ~/Applications/Dark Age of Camelot/  -- nothing system-wide is touched
#   3. The official DAoC patcher, which downloads the game (~4.5 GB)
#   4. A "Dark Age of Camelot" app in ~/Applications you double-click to play
#
# Re-running this script is safe: finished steps are skipped.

set -u
setopt NULL_GLOB

WINE_URL="https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.17/wine-devel-11.17-osx64.tar.xz"
WINE_VERSION="wine-11.17"   # Wine 11.0 stable has a WinHTTP race that hangs/crashes the DAoC patcher
WINE_SHA256="c2b3a8274dbc594deaa64e40469b607cbc4aa8ef5656dec4c5f6f3dac0da770c"

BASE="${DAOC_HOME:-$HOME/Applications/Dark Age of Camelot}"
WINE_DIR="$BASE/wine"
export WINEPREFIX="$BASE/prefix"
export WINEDEBUG=-all
export WINEDLLOVERRIDES="winemenubuilder.exe=d"   # don't spam ~/Applications with Wine shortcuts
PAYLOAD_URL="https://raw.githubusercontent.com/moynihan/daoc-apple-silicone/main/payload"
PAYLOAD="$(cd "$(dirname "$0")" 2>/dev/null && pwd)/payload"
[[ -f "$PAYLOAD/camelot.exe" ]] || PAYLOAD="$BASE/payload"
GAME="$WINEPREFIX/drive_c/Program Files (x86)/Electronic Arts/Dark Age of Camelot"
APP="${DAOC_APP:-$HOME/Applications/Dark Age of Camelot.app}"
LOG="$BASE/install.log"

say()  { print -P "%F{cyan}==>%f $*"; }
ok()   { print -P "%F{green}  ✓%f $*"; }
die()  { print -P "%F{red}ERROR:%f $*"; echo; echo "Details are in: $LOG"; echo "Press Return to close."; read -r </dev/tty 2>/dev/null; exit 1; }

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
WINE_BIN="$WINE_DIR/Wine Devel.app/Contents/Resources/wine/bin"
have=$("$WINE_BIN/wine" --version 2>/dev/null || "$WINE_DIR/Wine Stable.app/Contents/Resources/wine/bin/wine" --version 2>/dev/null)
if [[ "$have" == "$WINE_VERSION" ]]; then
  ok "Wine already installed ($have)"
else
  [[ -n "$have" ]] && say "Replacing Wine $have with $WINE_VERSION..."
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
  [[ "$("$WINE_BIN/wine" --version 2>/dev/null)" == "$WINE_VERSION" ]] || die "Wine does not start on this Mac."
  ok "Wine installed ($WINE_VERSION)"
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
  if [[ ! -f "$PAYLOAD/camelot.exe" || ! -f "$PAYLOAD/patch.cfg" ]]; then
    say "Downloading the DAoC patcher..."
    mkdir -p "$PAYLOAD"
    for f in camelot.exe patch.cfg daoc.icns; do
      curl -fsSL -o "$PAYLOAD/$f" "$PAYLOAD_URL/$f" || die "Could not download $f."
    done
  fi
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
cat > "$APP/Contents/MacOS/launch" <<'LAUNCH'
#!/bin/zsh
# Starts the DAoC patcher; press Play in it once it says 100%.
#
# The EA patcher fetches its manifest through WinHTTP in async mode and, under
# Wine, that step is a race: sometimes it page-faults, sometimes it hangs at
# "Retrieving manifest files", usually it works. Each launch is watched via the
# patcher's own log; a crash, a hang, or an early exit triggers a relaunch.
export WINEPREFIX="@@WINEPREFIX@@"
export WINEDEBUG=-all
export WINEDLLOVERRIDES="winemenubuilder.exe=d"
export PATH="@@WINE_BIN@@:$PATH"
GAME="@@GAME@@"
LOG="@@BASE@@/wine.log"
setopt NULL_GLOB
cd "$GAME" || exit 1
: > "$LOG"
plog() { cat "$GAME"/logs/*.Log 2>/dev/null; }
for attempt in $(seq 1 8); do
  pbefore=$(plog | wc -l | tr -d ' ')
  wine camelot.exe >> "$LOG" 2>&1 &
  t0=$(date +%s); tnp=0; verdict=""
  while (( $(date +%s) - t0 < 150 )); do
    sleep 3
    new=$(plog | tail -n +$((pbefore + 1)))
    # only look at lines after the patcher's own self-update restart
    after=$(printf '%s\n' "$new" | awk '/Nothing to patch for \[EAMythic Patcher\]/{buf=""; seen=1; next} seen{buf=buf $0 "\n"} END{printf "%s", buf}')
    if printf '%s' "$after" | grep -qE "Patch size is|Nothing to patch for \[DAoC Live\]|Patch Operation Complete"; then verdict=ok; break; fi
    if grep -q "page fault" "$LOG"; then verdict=crash; break; fi
    if (( tnp == 0 )) && printf '%s' "$new" | grep -q "Nothing to patch for \[EAMythic Patcher\]"; then tnp=$(date +%s); fi
    if (( tnp > 0 && $(date +%s) - tnp > 45 )); then verdict=hang; break; fi
    if (( $(date +%s) - t0 > 25 )) && ! pgrep -x camelot.bin >/dev/null && ! pgrep -x camelot.exe >/dev/null; then verdict=exited; break; fi
  done
  [[ -z "$verdict" ]] && verdict=timeout
  echo "launch attempt $attempt: $verdict" >> "$LOG"
  [[ "$verdict" == ok ]] && exit 0
  wineserver -k 2>/dev/null; sleep 3; : > "$LOG"
done
echo "giving up after 8 attempts" >> "$LOG"
exit 1
LAUNCH
sed -i '' -e "s|@@WINEPREFIX@@|$WINEPREFIX|g" -e "s|@@WINE_BIN@@|$WINE_BIN|g" -e "s|@@GAME@@|$GAME|g" -e "s|@@BASE@@|$BASE|g" "$APP/Contents/MacOS/launch"
chmod +x "$APP/Contents/MacOS/launch"
[[ -f "$PAYLOAD/daoc.icns" ]] && cp "$PAYLOAD/daoc.icns" "$APP/Contents/Resources/daoc.icns"
touch "$APP"
ok "App created: $APP"

# ---------------------------------------------------------------- 6. Patch
echo
say "Starting the DAoC patcher. It downloads the game (about 4.5 GB) —"
say "leave it alone until the top-left corner says 100%%, then press Play."
say "After that, just open 'Dark Age of Camelot' from ~/Applications to play."
echo
if [[ -z "${DAOC_NO_LAUNCH:-}" ]]; then
  open "$APP"
fi
echo "Done. You can close this window."
