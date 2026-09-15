#!/bin/zsh
# Double-click me. Runs install.sh from this folder, or fetches it if missing.
here="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$here/install.sh" ]]; then
  exec zsh "$here/install.sh"
else
  exec zsh -c 'curl -fsSL https://raw.githubusercontent.com/moynihan/daoc-apple-silicone/main/install.sh | zsh'
fi
