# Eject Data

A tiny macOS menu bar utility: **quit every app using an external drive, then eject it safely** — in one click.

Mac storage is expensive, so many people keep Docker images, WeChat data, Codex workspaces, or media libraries on an external SSD. Before unplugging, you have to quit each app that reads from that volume, then eject. Miss one, and the eject fails.

Eject Data turns those steps into one menu bar button.

## Features

- Lives in the menu bar; one click quits apps and ejects
- **Dry-run** preview: see who is using the volume without changing anything
- Detects processes via `lsof`
- Special handling for Docker Desktop (its VM holds the disk image)
- Works with any external volume (defaults to `/Volumes/Data`)
- Pure Swift + zsh, no third-party dependencies, MIT licensed

## Requirements

- macOS 13 or later
- Xcode Command Line Tools to build from source (`xcode-select --install`)

## Install

### From a release

1. Download `EjectData-v1.0.0-macOS-arm64.zip`
2. Unzip and drag `EjectData.app` into Applications
3. If Gatekeeper blocks it on first launch, right-click → Open. The app is ad-hoc signed and not notarized by Apple.

### From source

```bash
git clone https://github.com/lonelyness1/eject-data.git
cd eject-data
./build.sh
cp -R build/EjectData.app /Applications/
```

## Usage

1. Launch `EjectData.app`
2. An eject icon appears in the menu bar
3. Choose the volume with "选择要弹出的卷…" (Select volume) the first time
4. Run "仅预览占用 (dry-run)" to check the list
5. Click "退出应用并弹出" (Quit apps and eject); an alert shows the result

The app is a `LSUIElement` menu bar app: no Dock icon, no window.

### Standalone script

`Resources/eject-data.sh` works on its own:

```bash
./eject-data.sh --dry-run              # list processes only
./eject-data.sh                        # quit apps and eject /Volumes/Data
./eject-data.sh /Volumes/MyDisk        # custom volume
./eject-data.sh --force /Volumes/Data  # SIGTERM remaining processes
```

## How it works

1. `lsof` lists processes with open files under the volume
2. If Docker is running, quit Docker Desktop first (its VM holds `Docker.raw`)
3. Send AppleScript `quit` to each detected GUI app
4. Wait up to 20 seconds for the volume to be released
5. `diskutil eject`; on failure, print the remaining users

`--force` sends `SIGTERM` to non-GUI processes that still hold the volume.

## Caveats

- Apps with unsaved documents may show a save dialog; the script waits 20 seconds. Try dry-run first.
- Quitting other apps requires macOS Automation permission; macOS asks on first use.
- Only GUI apps are quit automatically; background CLI processes need `--force`.
- Refuses to eject system volumes (`/`, `/System/Volumes/*`).
- Ad-hoc signed, not notarized. Distributed binaries need right-click → Open.
- This tool does not address enclosure/hub power or USB enumeration issues.

## Project layout

```
eject-data/
├── Sources/
│   └── EjectData.swift      # menu bar app
├── Resources/
│   ├── Info.plist
│   └── eject-data.sh        # standalone script
├── build.sh
├── README.md
├── README.en.md
├── CHANGELOG.md
└── LICENSE
```

## License

[MIT](LICENSE)
