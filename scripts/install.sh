#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_DIR="$HOME/.config"
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

mkdir -p "$NIRI_DIR" "$QS_DIR"

if [ -f "$NIRI_DIR/config.kdl" ]; then
    backup="$NIRI_DIR/config.kdl.a16een-backup"
    echo "==> Backing up existing Niri config to $backup"
    cp "$NIRI_DIR/config.kdl" "$backup"
fi

cp "$ROOT_DIR/niri/config.kdl" "$NIRI_DIR/config.kdl"
cp "$ROOT_DIR/quickshell/shell.qml" "$QS_DIR/shell.qml"

echo "==> Installing A16EEN session launcher and login entry"
sudo install -Dm755 "$ROOT_DIR/scripts/start-a16een" /usr/local/bin/start-a16een
sudo install -Dm644 "$ROOT_DIR/session/a16een.desktop" /usr/share/wayland-sessions/a16een.desktop

echo
echo "A16EEN foundation installed."
echo "Select 'A16EEN' from your Wayland session list and log in."
