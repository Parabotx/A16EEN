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

interactive=1
for arg in "$@"; do
    case "$arg" in
        --non-interactive|-y) interactive=0 ;;
        --help|-h)
            echo "Usage: bash scripts/install.sh [--non-interactive]"
            exit 0
            ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

if [ "$interactive" -eq 1 ] && [ -t 0 ]; then
    printf '\033[1;36m\nA16EEN SETUP\033[0m\n'
    printf '%s\n' '──────────────────────────────────────────────'
    printf '1) Install missing dependencies + deploy A16EEN\n'
    printf '2) Deploy A16EEN without installing packages\n'
    printf '3) Cancel\n'
    printf 'Choose [1]: '
    read -r choice
    choice=${choice:-1}

    case "$choice" in
        1) ;;
        2) SKIP_DEPS=1 ;;
        3) echo "Cancelled."; exit 0 ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac
else
    SKIP_DEPS=0
fi

echo "==> Checking A16EEN dependencies"

if ! command -v pacman >/dev/null 2>&1; then
    echo "A16EEN's automatic installer targets Arch Linux."
    exit 1
fi

if [ "${SKIP_DEPS:-0}" != "1" ]; then
    missing_packages=""
    for package in $PACKAGES; do
        if ! pacman -Q "$package" >/dev/null 2>&1; then
            missing_packages="$missing_packages $package"
        fi
    done

    if [ -n "$missing_packages" ]; then
        echo "==> Missing packages:"
        printf '    %s\n' "$missing_packages"

        if [ "$interactive" -eq 1 ]; then
            printf "Install them with Arch's full-sync transaction (this may update other system packages too)? [Y/n]: "
            read -r confirm
            confirm=${confirm:-Y}
            case "$confirm" in
                Y|y|Yes|yes) ;;
                *) echo "Dependency installation cancelled."; exit 1 ;;
            esac
        fi

        # Arch is a rolling-release distribution: package installation is performed
        # as a full sync + upgrade so A16EEN does not create a partial-upgrade state.
        # The package names come only from PACKAGES above; no user input is interpolated.
        if ! sudo pacman -Syu --needed $missing_packages; then
            echo
            echo "The first package transaction failed."
            echo "This can happen when a mirror is temporarily out of sync with its database."

            if [ "$interactive" -eq 1 ] && [ -t 0 ]; then
                printf "Force-refresh the Arch package databases and retry? [Y/n]: "
                read -r retry
                retry=${retry:-Y}
                case "$retry" in
                    Y|y|Yes|yes)
                        sudo pacman -Syyu --needed $missing_packages
                        ;;
                    *)
                        echo "Dependency installation cancelled."
                        exit 1
                        ;;
                esac
            else
                echo "Run `sudo pacman -Syyu` once to refresh mirror databases, then run A16EEN again."
                exit 1
            fi
        fi
    else
        echo "==> All A16EEN dependencies are already installed."
    fi
else
    echo "==> Skipping dependency installation."
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
    echo "==> Backed up the previous A16EEN configuration."
    echo "    $BACKUP_DIR/config"
fi

if [ "$INSTALLED_COMMIT" = "$SOURCE_COMMIT" ]     && [ -f "$NIRI_DIR/config.kdl" ]     && [ -f "$QS_DIR/shell.qml" ]; then
    echo "==> A16EEN is already deployed at this revision."
else
    echo "==> Deploying A16EEN"

    TMP_DEPLOY=$(mktemp -d)
    cleanup_deploy() {
        rm -rf "$TMP_DEPLOY"
    }
    trap cleanup_deploy EXIT INT TERM

    mkdir -p "$TMP_DEPLOY/ui" "$TMP_DEPLOY/assets/wallpapers"
    cp "$ROOT_DIR/niri/config.kdl" "$TMP_DEPLOY/config.kdl"
    cp "$ROOT_DIR/quickshell/a16een/shell.qml" "$QS_DIR/shell.qml"
    cp "$ROOT_DIR/quickshell/a16een/ui/"*.qml "$TMP_DEPLOY/ui/"

    # Only replace compositor config after the source file has been copied successfully.
    cp "$TMP_DEPLOY/config.kdl" "$NIRI_DIR/config.kdl"
    cp "$TMP_DEPLOY/ui/"*.qml "$QS_DIR/ui/"

    if [ -f "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.png" ]; then
        cp "$ROOT_DIR/quickshell/a16een/assets/wallpapers/default.png"             "$QS_DIR/assets/wallpapers/default.png"
    fi

    rm -rf "$TMP_DEPLOY"
    trap - EXIT INT TERM
fi

printf '%s\n' "$SOURCE_COMMIT" > "$STATE_DIR/installed-commit"

echo "==> Installing A16EEN session launcher, updater and diagnostics"
sudo install -Dm755 "$ROOT_DIR/scripts/start-a16een" /usr/local/bin/start-a16een
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-update" /usr/local/bin/a16een-update
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-doctor" /usr/local/bin/a16een-doctor
sudo install -Dm644 "$ROOT_DIR/session/a16een.desktop" /usr/share/wayland-sessions/a16een.desktop

echo
echo "╭──────────────────────────────────────────────╮"
echo "│           A16EEN installation complete       │"
echo "╰──────────────────────────────────────────────╯"
echo "Run 'a16een-update' whenever you want to check for updates."
