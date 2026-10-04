#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Parabotx/A16EEN.git"
BRANCH="main"
DATA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/a16een"
SOURCE_DIR="$DATA_ROOT/source"
RUN_DIR=""

C_RESET="\033[0m"
C_CYAN="\033[36m"
C_BLUE="\033[94m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"
C_DIM="\033[2m"
C_BOLD="\033[1m"

say() { printf "%b%s%b\n" "$C_CYAN" "$1" "$C_RESET"; }
ok() { printf "%b✓ %s%b\n" "$C_GREEN" "$1" "$C_RESET"; }
warn() { printf "%b! %s%b\n" "$C_YELLOW" "$1" "$C_RESET"; }
die() { printf "%b✗ %s%b\n" "$C_RED" "$1" "$C_RESET" >&2; exit 1; }

interactive=1
for arg in "$@"; do
    case "$arg" in
        --non-interactive|-y) interactive=0 ;;
        --help|-h)
            cat <<'HELP'
A16EEN installer

Usage:
  bash install.sh                  Interactive install/update
  bash install.sh --non-interactive
HELP
            exit 0
            ;;
        *) die "Unknown option: $arg" ;;
    esac
done

printf "%b\n" "$C_BLUE$C_BOLD"
printf "╭──────────────────────────────────────────────╮\n"
printf "│                 A16EEN                       │\n"
printf "│        desktop install / update              │\n"
printf "╰──────────────────────────────────────────────╯\n"
printf "%b\n" "$C_RESET"

if [[ $EUID -eq 0 ]]; then
    die "Run A16EEN as a normal user, not root."
fi

[[ -r /etc/os-release ]] || die "Cannot identify the operating system."
source /etc/os-release

if [[ "${ID:-}" != "arch" ]]; then
    die "Automatic installation currently supports Arch Linux. Detected: ${PRETTY_NAME:-unknown}"
fi

command -v sudo >/dev/null 2>&1 || die "sudo is required."

if ! command -v pacman >/dev/null 2>&1; then
    die "pacman was not found. This installer is for Arch Linux."
fi

if [[ $interactive -eq 1 ]]; then
    printf "\n%b1)%b Install / update A16EEN\n" "$C_BOLD" "$C_RESET"
    printf "%b2)%b Exit\n" "$C_BOLD" "$C_RESET"
    printf "\nChoose [1]: "
    read -r choice
    choice="${choice:-1}"
    [[ "$choice" == "1" ]] || { echo "Cancelled."; exit 0; }

    printf "\n%bThis will install only A16EEN's fixed dependency set and add the A16EEN login session.%b\n" "$C_DIM" "$C_RESET"
    printf "Continue [Y/n]: "
    read -r confirm
    confirm="${confirm:-Y}"
    [[ "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]] || { echo "Cancelled."; exit 0; }
fi

say "Checking Git..."
if ! command -v git >/dev/null 2>&1; then
    say "Git is missing; installing it from the official Arch repositories."
    sudo pacman -S --needed git
fi
ok "Git ready"

mkdir -p "$DATA_ROOT"

if [[ -d "$SOURCE_DIR/.git" ]]; then
    if [[ -n "$(git -C "$SOURCE_DIR" status --porcelain)" ]]; then
        git -C "$SOURCE_DIR" status --short
        die "The A16EEN source checkout has local changes. Refusing to overwrite them."
    fi

    CURRENT_BRANCH="$(git -C "$SOURCE_DIR" branch --show-current)"
    [[ "$CURRENT_BRANCH" == "$BRANCH" ]] || die "A16EEN source checkout is on '$CURRENT_BRANCH'; refusing to switch branches."

    say "Checking for A16EEN updates..."
    if [[ "$(git -C "$SOURCE_DIR" rev-parse --is-shallow-repository)" == "true" ]]; then
        git -C "$SOURCE_DIR" fetch --unshallow origin "$BRANCH"
    else
        git -C "$SOURCE_DIR" fetch origin "$BRANCH"
    fi

    LOCAL_COMMIT="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
    REMOTE_COMMIT="$(git -C "$SOURCE_DIR" rev-parse "origin/$BRANCH")"

    if [[ "$LOCAL_COMMIT" == "$REMOTE_COMMIT" ]]; then
        ok "A16EEN is already up to date"
    else
        say "New A16EEN version found"
        git -C "$SOURCE_DIR" --no-pager log --oneline --decorate -5 "$LOCAL_COMMIT..$REMOTE_COMMIT" || true

        if ! git -C "$SOURCE_DIR" merge-base --is-ancestor "$LOCAL_COMMIT" "$REMOTE_COMMIT"; then
            die "The local A16EEN checkout is not behind main. Refusing a non-fast-forward update."
        fi

        git -C "$SOURCE_DIR" merge --ff-only "origin/$BRANCH"
        ok "A16EEN source updated"
    fi
else
    [[ ! -e "$SOURCE_DIR" ]] || die "A16EEN source path exists but is not a valid Git checkout: $SOURCE_DIR"

    say "Downloading A16EEN..."
    TEMP_SOURCE="$(mktemp -d "$DATA_ROOT/source.XXXXXX")"
    trap 'rm -rf "$TEMP_SOURCE"' EXIT INT TERM
    git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$TEMP_SOURCE"
    mv "$TEMP_SOURCE" "$SOURCE_DIR"
    trap - EXIT INT TERM
    ok "A16EEN downloaded"
fi

RUN_DIR="$SOURCE_DIR"

printf "\n"
say "Launching the A16EEN setup..."
if [[ $interactive -eq 1 ]]; then
    bash "$RUN_DIR/scripts/install.sh"
else
    bash "$RUN_DIR/scripts/install.sh" --non-interactive
fi

printf "\n%b%bA16EEN is ready.%b\n" "$C_GREEN" "$C_BOLD" "$C_RESET"
printf "%bSelect 'A16EEN' from your Wayland session list.%b\n" "$C_DIM" "$C_RESET"
printf "Updates later: %ba16een-update%b\n" "$C_BOLD" "$C_RESET"
