#!/bin/zsh
# Collects everything useful for troubleshooting a DAoC install into one text
# file on the Desktop. Run with:
#   curl -fsSL https://raw.githubusercontent.com/moynihan/daoc-apple-silicone/main/diagnose.sh | zsh
# No passwords or account names are collected.

BASE="${DAOC_HOME:-$HOME/Applications/Dark Age of Camelot}"
GAME="$BASE/prefix/drive_c/Program Files (x86)/Electronic Arts/Dark Age of Camelot"
OUT="$HOME/Desktop/DAoC-diagnostics.txt"
exec > "$OUT" 2>&1

h() { echo; echo "=== $* ==="; }
echo "DAoC diagnostics  $(date)"
h "Mac"; sw_vers; uname -m; sysctl -n machdep.cpu.brand_string
h "Rosetta"; /usr/bin/arch -x86_64 /usr/bin/true && echo "ok" || echo "MISSING"
h "Disk free"; df -h "$HOME" | tail -1
h "Install folder"; ls -la "$BASE" 2>&1
h "Wine"; "$BASE/wine/Wine Stable.app/Contents/Resources/wine/bin/wine" --version 2>&1
h "Game folder size / key files"; du -sh "$GAME" 2>&1; ls -la "$GAME"/camelot.exe "$GAME"/camelot.bin "$GAME"/game.dll "$GAME"/login.dll "$GAME"/mft.myp 2>&1
h "Running Wine processes"; ps -eo pid,etime,pcpu,rss,comm | grep -iE "camelot|login.dll|game.dll|wine" | grep -v grep
h "Patch server reachability (needs HTTP on port 1380)"
for u in "http://patch.daoc.eamythic.com:1380/daocpatch/live/patcher/manifest/patcher.prod" "http://patch.daoc.eamythic.com:1380/daocpatch/live/daoc/manifest/daoc-live.prod"; do
  printf "%s -> " "$u"; curl -s -m 15 -o /dev/null -w "HTTP %{http_code}, %{size_download} bytes, %{time_total}s\n" "$u" || echo "FAILED (curl exit $?)"
done
printf "DNS: "; dig +short patch.daoc.eamythic.com | tr '\n' ' '; echo
h "VPN / proxy hints"; scutil --proxy | grep -iE "Enable|Proxy" | grep -v " 0$"; ifconfig | grep -E "^(utun|ipsec|ppp)" | head -5
h "wine.log (last 60 lines, Vulkan noise removed)"; grep -vE "VK_|mvk|^\s" "$BASE/wine.log" 2>&1 | tail -60
h "Patcher logs (last 40 lines of each)"; for f in "$GAME"/logs/*.Log; do echo "--- $f"; tail -40 "$f"; done 2>&1
h "Launcher script"; cat "$HOME/Applications/Dark Age of Camelot.app/Contents/MacOS/launch" 2>&1
echo; echo "=== end ==="
exec > /dev/tty 2>&1
echo "Saved: $OUT"
echo "Send that file to whoever is helping you."
open -R "$OUT" 2>/dev/null
