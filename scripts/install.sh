#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_DIR="$HOME/.config/a16een"
NIRI_DIR="$CONFIG_DIR/niri"
QS_DIR="$CONFIG_DIR/quickshell/a16een"

echo "==> Installing A16EEN foundation"

if ! command -v niri >/dev/null 2>&1; then
    echo "Missing dependency: niri"
    echo "Install Niri first."
    exit 1
fi

if ! command -v qs >/dev/null 2>&1; then
    echo "Missing dependency: quickshell (qs)"
    echo "Install Quickshell first."
    exit 1
fi

mkdir -p "$NIRI_DIR" "$QS_DIR/ui" "$QS_DIR/assets/wallpapers"

cp "$ROOT_DIR/niri/config.kdl" "$NIRI_DIR/config.kdl"
cp "$ROOT_DIR/quickshell/a16een/shell.qml" "$QS_DIR/shell.qml"
cp "$ROOT_DIR/quickshell/a16een/ui/"*.qml "$QS_DIR/ui/"

if [ -f "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.webp" ]; then
    cp "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.webp"         "$QS_DIR/assets/wallpapers/default.webp"
else
    echo "==> Wallpaper not installed yet (optional)"
    echo "    Add: quickshell/a16een/assets/wallpapers/default.webp"
fi

echo "==> Installing A16EEN session launcher and login entry"
sudo install -Dm755 "$ROOT_DIR/scripts/start-a16een" /usr/local/bin/start-a16een
sudo install -Dm644 "$ROOT_DIR/session/a16een.desktop" /usr/share/wayland-sessions/a16een.desktop

echo
echo "A16EEN foundation installed."
echo "Select 'A16EEN' from your Wayland session list and log in."
