#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_DIR="$HOME/.config/a16een"
NIRI_DIR="$CONFIG_DIR/niri"
QS_DIR="$CONFIG_DIR/quickshell/a16een"

PACKAGES="
niri
quickshell
foot
fuzzel
brightnessctl
playerctl
pipewire
wireplumber
upower
swaylock
xwayland-satellite
xdg-desktop-portal-gtk
networkmanager
bluez
bluez-utils
nm-connection-editor
"

echo "==> Installing A16EEN foundation"

if ! command -v pacman >/dev/null 2>&1; then
    echo "A16EEN's automatic installer targets Arch Linux."
    exit 1
fi

echo "==> Installing required packages from the official Arch repositories"
# Arch does not support partial upgrades, so the package transaction uses -Syu.
# The exact package list is fixed by this project; no user input is interpolated.
sudo pacman -Syu --needed --noconfirm $PACKAGES

echo "==> Installing A16EEN shell files"
mkdir -p "$NIRI_DIR" "$QS_DIR/ui" "$QS_DIR/assets/wallpapers"

cp "$ROOT_DIR/niri/config.kdl" "$NIRI_DIR/config.kdl"
cp "$ROOT_DIR/quickshell/a16een/shell.qml" "$QS_DIR/shell.qml"
cp "$ROOT_DIR/quickshell/a16een/ui/"*.qml "$QS_DIR/ui/"

if [ -f "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.webp" ]; then
    cp "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.webp"         "$QS_DIR/assets/wallpapers/default.webp"
else
    echo "==> No default wallpaper found."
    echo "    Add quickshell/a16een/assets/wallpapers/default.webp to the repository later."
fi

echo "==> Installing A16EEN session launcher and login entry"
sudo install -Dm755 "$ROOT_DIR/scripts/start-a16een" /usr/local/bin/start-a16een
sudo install -Dm644 "$ROOT_DIR/session/a16een.desktop" /usr/share/wayland-sessions/a16een.desktop

echo
echo "╭──────────────────────────────────────────────╮"
echo "│           A16EEN installation complete       │"
echo "╰──────────────────────────────────────────────╯"
echo
echo "Select 'A16EEN' in your display manager's session list."
echo "Your existing ~/.config/niri configuration was not modified."
echo
