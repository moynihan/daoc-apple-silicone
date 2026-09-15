# Dark Age of Camelot on Apple Silicon

Runs the official Broadsword DAoC client (32-bit, DirectX 9) on an Apple
Silicon Mac using WineHQ's macOS build of Wine 11, without CrossOver,
Whisky, Homebrew, or a Windows VM.

## What's here

| Path | Purpose |
|------|---------|
| `installer/Install DAoC.command` | One-click installer to send to a friend (see `installer/README.txt`) |
| `installer/payload/` | The two bootstrap files from the official `DAoCSetup.exe` (patcher + patch config) and an app icon |
| `DAoCSetup.exe` | The official installer, unchanged (SHA-256 `89785e16…bedd9`, identical to the current download) |
| `env.sh`, `play.sh` | Dev/test harness that runs the game from a Wine prefix inside this folder |
| `wine/`, `prefix/` | Scratch Wine install + prefix used while working this out (safe to delete) |

Your playable install lives in `~/Applications/Dark Age of Camelot/` and is
launched with `~/Applications/Dark Age of Camelot.app`.

## How it works

1. `DAoCSetup.exe` is a WinRAR self-extractor around an NSIS `setup.exe`.
   All it really does is copy `camelot.exe` (the EA Mythic patcher) and
   `patch.cfg` into `Program Files (x86)\Electronic Arts\Dark Age of Camelot`
   and install DirectX 9 redistributables (unneeded under Wine). Its silent
   mode doesn't work under Wine, so the installer copies those two files itself.
2. `camelot.exe` self-updates, then downloads the game (~4.4 GB) from
   `patch.daoc.eamythic.com`. That server is still live in 2026.
3. Pressing Play runs `login.dll` (the login client), which launches `game.dll`.

Wine settings that matter: default 64-bit prefix (Wine 11's WoW64 mode runs
the 32-bit client; `WINEARCH=win32` is not supported), Windows version set
to 7, crash dialog disabled, `winemenubuilder` disabled so Wine doesn't
create stray shortcuts. Rendering uses Wine's built-in wined3d (D3D9 → OpenGL).

## Verified

Patcher, login client and the 3D client (`game.dll`, character select at
1920×1200, wined3d/OpenGL) all run on an Apple Silicon Mac with macOS 26.5.
Known quirk: the first Play after a fresh patch may crash the client; the
second launch works. Wine output goes to `~/Applications/Dark Age of Camelot/wine.log`.

## If the 3D client ever misbehaves

DXVK-macOS does not ship a D3D9 DLL, so the Vulkan/Metal fallbacks are
[Sikarugir](https://github.com/Sikarugir-App/Sikarugir) (free, bundles D9VK)
or CrossOver with DXVK enabled.

Reports from Eden (a DAoC freeshard) users: CrossOver 22/23 on M2/M3 crashed
on camera movement or after loading NPCs; Parallels and VMware Fusion worked.

## Why Homebrew's `wine-stable` failed

Homebrew disabled every WineHQ cask on 2026-09-01 because the packages don't
pass its Gatekeeper check. The tarball from WineHQ's own GitHub releases is
the same build; the installer downloads it directly and clears the
quarantine attribute.
