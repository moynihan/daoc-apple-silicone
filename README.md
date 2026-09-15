# Dark Age of Camelot on Apple Silicon Macs

Play the official (Broadsword) Dark Age of Camelot client on an M1/M2/M3/M4
Mac. No CrossOver, no Parallels, no Homebrew. One install step, then a normal
Mac app you double-click.

## Install (pick one)

### A. Paste one line into Terminal

1. Open **Terminal** (press ⌘-Space, type `Terminal`, press Return).
2. Paste this line and press Return:

```bash
curl -fsSL https://raw.githubusercontent.com/moynihan/daoc-apple-silicone/main/install.sh | zsh
```

3. It may ask for your Mac password once (to install Apple's Rosetta).
   Wait until it says **Done**.

### B. Download and double-click

1. Download **DAoC-Mac-Installer.zip** from the
   [Releases page](https://github.com/moynihan/daoc-apple-silicone/releases/latest)
   and open it (Safari usually unzips it for you).
2. Double-click **Install DAoC.command**.
3. If macOS says it "can't be opened" or "cannot verify" it: open
   **System Settings → Privacy & Security**, scroll down, click **Open Anyway**,
   then double-click the file again. (Newer macOS versions do this for
   anything not from the App Store.)

## Then play

1. The DAoC patcher window appears and downloads the game (about 4.5 GB,
   5–30 minutes depending on your internet). Leave it alone until the
   top-left corner says **100%**.
2. Press **Play** and log in. No account yet? Free "Endless Conquest"
   accounts: <https://accounts.eamythic.com/>
3. If the game ever closes itself right after you press Play, open it
   again and log in. (The launcher already retries the patcher for you.)
4. From now on, open **Dark Age of Camelot** in your home folder's
   Applications folder (Finder → Go → Home → Applications). Want it in the
   Dock? Drag it there.

### Something not working?

Paste this line into Terminal. It writes `DAoC-diagnostics.txt` to your
Desktop (no passwords or account names in it); send that file to whoever is
helping you:

```bash
curl -fsSL https://raw.githubusercontent.com/moynihan/daoc-apple-silicone/main/diagnose.sh | zsh
```

Stuck at **0 % "Retrieving manifest files"** or the patcher vanishes: with
Wine 11.0 the EA patcher's async WinHTTP requests sometimes deadlock or
page-fault at that step (roughly half of fresh runs in testing). The installer
now ships Wine 11.17, which passed 8/8 fresh runs, and the launcher watches the
patcher's log and relaunches it on a crash, hang, or early exit (up to 8
times). If you installed before this change, just rerun the install line; it
swaps Wine in place and keeps your game files.

Everything lives in `~/Applications/Dark Age of Camelot/`. To uninstall,
drag that folder and the **Dark Age of Camelot** app to the Trash. If
something goes wrong, the log file is `~/Applications/Dark Age of Camelot/wine.log`.

## Requirements

* Apple Silicon Mac (M1 or newer), macOS 13 or newer.
* About 7 GB of free disk space.
* A DAoC account (free Endless Conquest or subscription).

Verified on macOS 26.5: patcher, login client, and the 3D game client all run,
rendering at full resolution.

---

## For developers

```bash
make install   # same as the one-liner, from this checkout
make zip       # build DAoC-Mac-Installer.zip (what the Releases page serves)
make release   # tag + publish the zip to GitHub Releases (needs gh)
make clean     # remove scratch wine/ and prefix/ folders
```

| Path | Purpose |
|------|---------|
| `install.sh` | The installer. Idempotent; safe to re-run. `DAOC_HOME`, `DAOC_APP`, `DAOC_NO_LAUNCH` env vars override paths / skip the final launch (used for testing) |
| `Install DAoC.command` | Double-click wrapper around `install.sh` (falls back to fetching it) |
| `payload/` | The two bootstrap files from the official `DAoCSetup.exe` (patcher + patch config) and an app icon |
| `INSTALL.txt` | Plain-text instructions shipped inside the zip |
| `env.sh`, `play.sh` | Dev harness that runs the game from a Wine prefix inside this folder |

### How it works

1. `DAoCSetup.exe` (the official installer, SHA-256 `89785e16…bedd9`) is a
   WinRAR self-extractor around an NSIS `setup.exe`. All it really does is copy
   `camelot.exe` (the EA Mythic patcher) and `patch.cfg` into
   `Program Files (x86)\Electronic Arts\Dark Age of Camelot` and install
   DirectX 9 redistributables (unneeded under Wine). Its silent mode doesn't
   work under Wine, so the installer copies those two files itself.
2. `camelot.exe` self-updates, then downloads the game (~4.4 GB) from
   `patch.daoc.eamythic.com`. That server is still live in 2026.
3. Pressing Play runs `login.dll` (the login client), which launches `game.dll`
   (32-bit, DirectX 9).

Wine: WineHQ's own macOS build of Wine 11.17 (devel branch), downloaded from
[Gcenx/macOS_Wine_builds](https://github.com/Gcenx/macOS_Wine_builds) and
installed privately (Homebrew disabled its WineHQ casks on 2026-09-01 over a
Gatekeeper check). Default 64-bit prefix (Wine 11's WoW64 mode runs the
32-bit client; `WINEARCH=win32` is not supported). Windows version set to 7,
crash dialog disabled, `winemenubuilder` disabled. Rendering is Wine's
built-in wined3d (D3D9 → OpenGL); no winetricks needed.

### If the 3D client ever misbehaves

DXVK-macOS does not ship a D3D9 DLL, so the Vulkan/Metal fallbacks are
[Sikarugir](https://github.com/Sikarugir-App/Sikarugir) (free, bundles D9VK)
or CrossOver with DXVK enabled.
