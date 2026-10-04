#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_DIR="$HOME/.config/a16een"
STATE_DIR="$HOME/.local/state/a16een"
NIRI_DIR="$CONFIG_DIR/niri"
QS_DIR="$CONFIG_DIR/quickshell/a16een"
BACKUP_ROOT="$STATE_DIR/backups"

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

echo "==> Checking A16EEN dependencies"

if ! command -v pacman >/dev/null 2>&1; then
    echo "A16EEN's automatic installer targets Arch Linux."
    exit 1
fi

missing_packages=""
for package in $PACKAGES; do
    if ! pacman -Q "$package" >/dev/null 2>&1; then
        missing_packages="$missing_packages $package"
    fi
done

if [ -n "$missing_packages" ]; then
    echo "==> Installing missing packages from the official Arch repositories"
    # Only fixed package names from this project are passed to pacman.
    # Existing packages are not reinstalled.
    sudo pacman -S --needed --noconfirm $missing_packages
else
    echo "==> All A16EEN dependencies are already installed."
fi

SOURCE_COMMIT="unknown"
if command -v git >/dev/null 2>&1 && git -C "$ROOT_DIR" rev-parse HEAD >/dev/null 2>&1; then
    SOURCE_COMMIT=$(git -C "$ROOT_DIR" rev-parse HEAD)
fi

mkdir -p "$NIRI_DIR" "$QS_DIR/ui" "$QS_DIR/assets/wallpapers" "$BACKUP_ROOT"

INSTALLED_COMMIT=""
if [ -f "$STATE_DIR/installed-commit" ]; then
    INSTALLED_COMMIT=$(cat "$STATE_DIR/installed-commit")
fi

if [ -n "$INSTALLED_COMMIT" ] && [ "$INSTALLED_COMMIT" != "$SOURCE_COMMIT" ] && [ -d "$CONFIG_DIR" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    cp -a "$CONFIG_DIR" "$BACKUP_DIR/config"
    echo "==> Backed up previous A16EEN configuration to:"
    echo "    $BACKUP_DIR/config"
fi

if [ "$INSTALLED_COMMIT" = "$SOURCE_COMMIT" ]     && [ -f "$NIRI_DIR/config.kdl" ]     && [ -f "$QS_DIR/shell.qml" ]; then
    echo "==> A16EEN files are already at this revision. Skipping file deployment."
else
    echo "==> Deploying A16EEN shell and compositor configuration"
    cp "$ROOT_DIR/niri/config.kdl" "$NIRI_DIR/config.kdl"
    cp "$ROOT_DIR/quickshell/a16een/shell.qml" "$QS_DIR/shell.qml"
    cp "$ROOT_DIR/quickshell/a16een/ui/"*.qml "$QS_DIR/ui/"

    if [ -f "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.png" ]; then
        cp "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.png"             "$QS_DIR/assets/wallpapers/default.png"
    fi
fi

echo "$SOURCE_COMMIT" > "$STATE_DIR/installed-commit"

echo "==> Installing A16EEN session launcher, updater and diagnostics"
sudo install -Dm755 "$ROOT_DIR/scripts/start-a16een" /usr/local/bin/start-a16een
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-update" /usr/local/bin/a16een-update
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-doctor" /usr/local/bin/a16een-doctor
sudo install -Dm644 "$ROOT_DIR/session/a16een.desktop" /usr/share/wayland-sessions/a16een.desktop

echo
echo "╭──────────────────────────────────────────────╮"
echo "│           A16EEN installation complete       │"
echo "╰──────────────────────────────────────────────╯"
echo "Run 'a16een-update' whenever you want to pull the latest A16EEN release."
