#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_DIR="$HOME/.config/a16een"
STATE_DIR="$HOME/.local/state/a16een"
NIRI_DIR="$CONFIG_DIR/niri"
QS_DIR="$CONFIG_DIR/quickshell/a16een"
BACKUP_ROOT="$STATE_DIR/backups"
USER_WALLPAPER_DIR="$HOME/Pictures/a16een"
WALLPAPER_STATE="$STATE_DIR/wallpaper"

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
grim
wl-clipboard
jq
bluez
bluez-utils
nm-connection-editor
wlsunset
curl
xdg-desktop-portal
xdg-desktop-portal-gtk
xdg-utils
qt6-imageformats
qt6-svg
hicolor-icon-theme
adwaita-icon-theme
power-profiles-daemon
inter-font
ttf-lato
adobe-source-sans-fonts
ttf-roboto
ttf-roboto-mono
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

mkdir -p "$NIRI_DIR" "$QS_DIR/ui" "$QS_DIR/assets/wallpapers" "$QS_DIR/assets/animated" "$BACKUP_ROOT" "$USER_WALLPAPER_DIR" "$USER_WALLPAPER_DIR/animated"

# A16EEN has two wallpaper stores:
#   1. Built-in wallpapers shipped in the GitHub repository.
#   2. Personal wallpapers in the user's Pictures/a16een folder.
# The personal folder is never overwritten by A16EEN updates.
mkdir -p "$USER_WALLPAPER_DIR"

if [ ! -f "$WALLPAPER_STATE" ] || [ ! -s "$WALLPAPER_STATE" ]; then
    printf '%s\t%s\n' "builtin" "default.png" > "$WALLPAPER_STATE"
fi

INSTALLED_COMMIT=""
if [ -f "$STATE_DIR/installed-commit" ]; then
    INSTALLED_COMMIT=$(cat "$STATE_DIR/installed-commit")
fi

if [ "$INSTALLED_COMMIT" != "$SOURCE_COMMIT" ] && [ -d "$CONFIG_DIR" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    cp -a "$CONFIG_DIR" "$BACKUP_DIR/config"

    if [ -n "$INSTALLED_COMMIT" ]; then
        printf '%s\n' "$INSTALLED_COMMIT" > "$BACKUP_DIR/source-commit"
    fi

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

    mkdir -p "$TMP_DEPLOY/ui" "$TMP_DEPLOY/assets/wallpapers" "$TMP_DEPLOY/assets/animated" "$TMP_DEPLOY/assets/icons"
    cp "$ROOT_DIR/niri/config.kdl" "$TMP_DEPLOY/config.kdl"
    cp "$ROOT_DIR/quickshell/a16een/shell.qml" "$TMP_DEPLOY/shell.qml"
    cp "$ROOT_DIR/quickshell/a16een/ui/"*.qml "$TMP_DEPLOY/ui/"
    cp "$ROOT_DIR/quickshell/a16een/ui/"*.js "$TMP_DEPLOY/ui/"
    cp "$ROOT_DIR/quickshell/a16een/assets/icons/"*.svg "$TMP_DEPLOY/assets/icons/"

    # Ship every supported built-in wallpaper from the dedicated repository folder.
    BUILTIN_SOURCE_DIR="$ROOT_DIR/quickshell/a16een/assets/wallpapers"
    while IFS= read -r -d '' wallpaper; do
        relative="${wallpaper#"$BUILTIN_SOURCE_DIR"/}"
        destination="$TMP_DEPLOY/assets/wallpapers/$relative"
        mkdir -p "$(dirname "$destination")"
        cp "$wallpaper" "$destination"
    done < <(
        find "$BUILTIN_SOURCE_DIR" -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \
            -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.tga' \
            -o -iname '*.svg' -o -iname '*.ppm' -o -iname '*.pgm' -o -iname '*.pbm' \
            -o -iname '*.xpm' -o -iname '*.xbm' \) -print0 | LC_ALL=C sort -z -f
    )

    # Ship built-in animated wallpapers separately from static wallpapers.
    BUILTIN_ANIMATED_SOURCE_DIR="$ROOT_DIR/quickshell/a16een/assets/animated"
    if [ -d "$BUILTIN_ANIMATED_SOURCE_DIR" ]; then
        while IFS= read -r -d '' wallpaper; do
            relative="${wallpaper#"$BUILTIN_ANIMATED_SOURCE_DIR"/}"
            destination="$TMP_DEPLOY/assets/animated/$relative"
            mkdir -p "$(dirname "$destination")"
            cp "$wallpaper" "$destination"
        done < <(
            find "$BUILTIN_ANIMATED_SOURCE_DIR" -maxdepth 1 -type f                 \( -iname '*.gif' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.mkv' \)                 -print0 | LC_ALL=C sort -z -f
        )
    fi

    # Compatibility migration for wallpapers added to the repository root
    # by the earlier wallpaper setup. Existing files are imported automatically.
    while IFS= read -r -d '' wallpaper; do
        name="${wallpaper##*/}"
        destination="$TMP_DEPLOY/assets/wallpapers/$name"
        [ -e "$destination" ] || cp "$wallpaper" "$destination"
    done < <(
        find "$ROOT_DIR" -maxdepth 1 -type f \
            \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \
            -o -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.tga' \
            -o -iname '*.svg' -o -iname '*.ppm' -o -iname '*.pgm' -o -iname '*.pbm' \
            -o -iname '*.xpm' -o -iname '*.xbm' \) -print0 | LC_ALL=C sort -z -f
    )

    # Never install a new compositor config that Niri cannot parse.
    if command -v niri >/dev/null 2>&1; then
        if ! niri validate --config "$TMP_DEPLOY/config.kdl"; then
            echo "==> A16EEN deployment stopped: Niri rejected the staged configuration." >&2
            exit 1
        fi
    else
        echo "WARNING: niri is not installed; skipping staged Niri validation." >&2
    fi

    # Replace only after every staged file was copied and the compositor config validated.
    cp "$TMP_DEPLOY/config.kdl" "$NIRI_DIR/config.kdl"
    cp "$TMP_DEPLOY/shell.qml" "$QS_DIR/shell.qml"
    cp "$TMP_DEPLOY/ui/"*.qml "$QS_DIR/ui/"
    cp "$TMP_DEPLOY/ui/"*.js "$QS_DIR/ui/"

    # Replace only the built-in runtime library. Personal wallpapers live elsewhere.
    find "$QS_DIR/assets/wallpapers" -type f -delete
    cp -a "$TMP_DEPLOY/assets/wallpapers/." "$QS_DIR/assets/wallpapers/"

    find "$QS_DIR/assets/animated" -type f -delete
    cp -a "$TMP_DEPLOY/assets/animated/." "$QS_DIR/assets/animated/"

    mkdir -p "$QS_DIR/assets/icons"
    cp "$TMP_DEPLOY/assets/icons/"*.svg "$QS_DIR/assets/icons/"

    rm -rf "$TMP_DEPLOY"
    trap - EXIT INT TERM
fi

printf '%s\n' "$SOURCE_COMMIT" > "$STATE_DIR/installed-commit"

# Apply the deployed compositor configuration immediately when updating an
# already-running A16EEN session. Without this, new keybindings would not take
# effect until the next login.
if [ "${XDG_CURRENT_DESKTOP:-}" = "A16EEN" ] && command -v niri >/dev/null 2>&1; then
    if niri msg action load-config-file >/dev/null 2>&1; then
        echo "==> Reloaded the active Niri configuration."
    else
        echo "WARNING: could not reload the active Niri configuration; re-enter A16EEN to apply compositor changes." >&2
    fi
fi

if command -v systemctl >/dev/null 2>&1 && command -v powerprofilesctl >/dev/null 2>&1; then
    if sudo systemctl enable --now power-profiles-daemon.service >/dev/null 2>&1; then
        echo "==> Power Profiles Daemon is enabled and active."
    else
        echo "WARNING: could not start power-profiles-daemon; A16EEN power commands may be unavailable until it is started." >&2
    fi
fi

echo "==> Installing A16EEN session launcher, shell supervisor, updater and diagnostics"
sudo install -Dm755 "$ROOT_DIR/scripts/start-a16een" /usr/local/bin/start-a16een
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-shell" /usr/local/bin/a16een-shell
sudo install -Dm755 "$ROOT_DIR/scripts/a16een" /usr/local/bin/a16een
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-wallpaper" /usr/local/bin/a16een-wallpaper
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-screenshot" /usr/local/bin/a16een-screenshot
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-control" /usr/local/bin/a16een-control
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-icon-theme" /usr/local/bin/a16een-icon-theme

# The first revision with icon themes could leave a theme selected that is
# expensive or incomplete. Reset once to the system default for a clean,
# performance-safe migration. Users can select a theme again from /icons.
if [ ! -f "$STATE_DIR/icon-theme-migration-v1" ] &&
   { [ -f "$STATE_DIR/icon-theme" ] || [ -f "$STATE_DIR/previous-gsettings-icon-theme" ]; }; then
    /usr/local/bin/a16een-icon-theme set system >/dev/null 2>&1 || true
    : > "$STATE_DIR/icon-theme-migration-v1"
fi
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-icons" /usr/local/bin/a16een-icons
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-update" /usr/local/bin/a16een-update
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-doctor" /usr/local/bin/a16een-doctor
sudo install -Dm644 "$ROOT_DIR/session/a16een.desktop" /usr/share/wayland-sessions/a16een.desktop

# Install A16EEN's portal preference only when the user does not already have one.
# This avoids overwriting portal choices made for another desktop/session.
PORTAL_DIR="$HOME/.config/xdg-desktop-portal"
PORTAL_CONF="$PORTAL_DIR/a16een-portals.conf"
if [ ! -f "$PORTAL_CONF" ]; then
    mkdir -p "$PORTAL_DIR"
    cp "$ROOT_DIR/xdg/xdg-desktop-portal/a16een-portals.conf" "$PORTAL_CONF"
    echo "==> Installed A16EEN XDG portal preference."
else
    echo "==> Preserved existing A16EEN portal preference."
fi

echo "==> Syncing A16EEN UI icons"
if ! bash "$ROOT_DIR/scripts/a16een-icons"; then
    echo "WARNING: icon synchronization failed; using the bundled fallback SVGs." >&2
fi

# If A16EEN is already running, restart only its Quickshell process after
# deployment. This is especially important when a revision adds or removes QML
# component files, which a live hot-reload may not register reliably.
if [ "${XDG_CURRENT_DESKTOP:-}" = "A16EEN" ]; then
    CONFIG_SHELL_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/a16een/quickshell/a16een"
    RESTARTED_SHELL=0

    for cmdline in /proc/[0-9]*/cmdline; do
        [ -r "$cmdline" ] || continue
        PID="${cmdline#/proc/}"
        PID="${PID%/cmdline}"
        case "$PID" in
            ''|*[!0-9]*) continue ;;
        esac

        ARGS="$(tr '\0' ' ' < "$cmdline" 2>/dev/null || true)"
        case "$ARGS" in
            *"qs -c $CONFIG_SHELL_DIR"*)
                if kill -TERM "$PID" 2>/dev/null; then
                    RESTARTED_SHELL=1
                fi
                ;;
        esac
    done

    if [ "$RESTARTED_SHELL" -eq 1 ]; then
        echo "==> Restarted the A16EEN Quickshell shell."
    fi

    # If the supervisor itself exited after repeated QML failures, recover it
    # without requiring the user to leave the desktop session.
    if ! pgrep -f '[a]16een-shell' >/dev/null 2>&1; then
        nohup /usr/local/bin/a16een-shell >/dev/null 2>&1 &
        echo "==> Started the A16EEN shell supervisor."
    fi
fi

echo
echo "╭──────────────────────────────────────────────╮"
echo "│           A16EEN installation complete       │"
echo "╰──────────────────────────────────────────────╯"
echo "Run 'a16een-update' whenever you want to check for updates."
echo "Built-in wallpapers: $QS_DIR/assets/wallpapers"
echo "Personal wallpapers: $USER_WALLPAPER_DIR"
echo "Personal animated wallpapers: $USER_WALLPAPER_DIR/animated"
