#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Parabotx/A16EEN.git"
BRANCH="main"
INSTALL_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/a16een-installer"

cleanup() {
    rm -rf "$INSTALL_DIR"
}
trap cleanup EXIT INT TERM

echo "╭──────────────────────────────────────────────╮"
echo "│                 A16EEN                       │"
echo "│        One-command Arch installer            │"
echo "╰──────────────────────────────────────────────╯"
echo

if [[ $EUID -eq 0 ]]; then
    echo "Please run this installer as a normal user, not root."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    echo "Cannot identify the operating system."
    exit 1
fi

# A16EEN currently targets Arch Linux because Niri + Quickshell are
# available directly from the official Arch repositories.
source /etc/os-release
if [[ "${ID:-}" != "arch" ]]; then
    echo "A16EEN's automatic installer currently supports Arch Linux."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "Missing dependency: sudo"
    exit 1
fi

echo "==> Installing Git from the official Arch repositories..."
sudo pacman -Syu --needed  git

rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"

echo "==> Downloading A16EEN from GitHub..."
git clone --depth 1 --branch "$BRANCH" --single-branch "$REPO_URL" "$INSTALL_DIR"

echo "==> Running A16EEN installer..."
bash "$INSTALL_DIR/scripts/install.sh" "$@"
