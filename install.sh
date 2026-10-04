#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Parabotx/A16EEN.git"
BRANCH="main"
DATA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/a16een"
SOURCE_DIR="$DATA_ROOT/source"
RUN_DIR=""

cleanup() {
    true
}
trap cleanup EXIT INT TERM

echo "╭──────────────────────────────────────────────╮"
echo "│                 A16EEN                       │"
echo "│     one-command install / update             │"
echo "╰──────────────────────────────────────────────╯"
echo

if [[ $EUID -eq 0 ]]; then
    echo "Please run A16EEN as a normal user, not root."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    echo "Cannot identify the operating system."
    exit 1
fi

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

echo "==> Checking Git..."
if ! command -v git >/dev/null 2>&1; then
    echo "Git is missing. Installing it from the official Arch repositories..."
    sudo pacman -S --needed --noconfirm git
fi

# When run from an existing A16EEN checkout, use that checkout.
if [[ -f "${BASH_SOURCE[0]}" && -d "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.git" ]]; then
    CANDIDATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    CANDIDATE_REMOTE="$(git -C "$CANDIDATE_DIR" remote get-url origin 2>/dev/null || true)"
    if [[ "$CANDIDATE_REMOTE" == "$REPO_URL" ]]; then
        RUN_DIR="$CANDIDATE_DIR"
    fi
fi

mkdir -p "$DATA_ROOT"

if [[ -z "$RUN_DIR" ]]; then
    if [[ -d "$SOURCE_DIR/.git" ]]; then
        if [[ -n "$(git -C "$SOURCE_DIR" status --porcelain)" ]]; then
            echo "A16EEN source checkout has local changes:"
            git -C "$SOURCE_DIR" status --short
            echo
            echo "Refusing to overwrite those changes during an update."
            echo "Commit/stash the changes, or remove the checkout and run again."
            exit 1
        fi

        echo "==> Checking for A16EEN updates..."
        git -C "$SOURCE_DIR" fetch --depth 1 origin "$BRANCH"

        LOCAL_COMMIT="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
        REMOTE_COMMIT="$(git -C "$SOURCE_DIR" rev-parse "origin/$BRANCH")"

        if [[ "$LOCAL_COMMIT" == "$REMOTE_COMMIT" ]]; then
            echo "==> A16EEN is already up to date."
        else
            echo "==> Updating A16EEN to the latest main branch..."
            git -C "$SOURCE_DIR" merge --ff-only "origin/$BRANCH"
        fi
    else
        echo "==> Cloning A16EEN..."
        rm -rf "$SOURCE_DIR.tmp"
        git clone --depth 1 --branch "$BRANCH" --single-branch "$REPO_URL" "$SOURCE_DIR.tmp"
        mv "$SOURCE_DIR.tmp" "$SOURCE_DIR"
    fi

    RUN_DIR="$SOURCE_DIR"
else
    echo "==> Using existing A16EEN checkout."
fi

echo "==> Applying A16EEN..."
bash "$RUN_DIR/scripts/install.sh" "$@"

echo
echo "A16EEN is installed/updated."
echo "Select 'A16EEN' from your Wayland session list."
