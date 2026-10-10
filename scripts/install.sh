#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CONFIG_DIR="$HOME/.config/a16een"
STATE_DIR="$HOME/.local/state/a16een"
NIRI_DIR="$CONFIG_DIR/niri"
QS_DIR="$CONFIG_DIR/quickshell/a16een"
LOCKSCREEN_DIR="$CONFIG_DIR/lockscreen"
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
mpv
python
pipewire
wireplumber
upower
swaylock
gtklock
ffmpeg
xwayland-satellite
xdg-desktop-portal-gtk
networkmanager
grim
imagemagick
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
qt6-multimedia
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
    if ! command -v gtklock >/dev/null 2>&1; then
        echo "WARNING: GTKLock is not available in PATH."
        echo "         The custom lock-screen clock, date, card, and corner badge require GTKLock."
        echo "         A16EEN will keep the secure swaylock fallback, which may show only the wallpaper."
        echo "         Option 2 skips packages; install GTKLock separately to enable the full lock-screen design."
    fi
fi

SOURCE_COMMIT="unknown"
if command -v git >/dev/null 2>&1 && git -C "$ROOT_DIR" rev-parse HEAD >/dev/null 2>&1; then
    SOURCE_COMMIT=$(git -C "$ROOT_DIR" rev-parse HEAD)
fi

mkdir -p "$NIRI_DIR" "$QS_DIR/ui" "$QS_DIR/assets/wallpapers" "$QS_DIR/assets/animated" "$BACKUP_ROOT" "$USER_WALLPAPER_DIR" "$USER_WALLPAPER_DIR/animated"
# Event file used by the lightweight volume/brightness OSD watcher.
# It is intentionally separate from Quickshell's private state directory.
printf '%s\n' "" > "$STATE_DIR/control-indicator"

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
    cp "$ROOT_DIR/quickshell/a16een/assets/quotes.json" "$TMP_DEPLOY/assets/quotes.json"

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
    # Remove obsolete experimental navbar renderers from older A16EEN revisions.
    rm -f "$QS_DIR/ui/ArtGlyph.qml"
    cp "$TMP_DEPLOY/ui/"*.qml "$QS_DIR/ui/"
    cp "$TMP_DEPLOY/ui/"*.js "$QS_DIR/ui/"

    # Replace only the built-in runtime library. Personal wallpapers live elsewhere.
    find "$QS_DIR/assets/wallpapers" -type f -delete
    cp -a "$TMP_DEPLOY/assets/wallpapers/." "$QS_DIR/assets/wallpapers/"

    find "$QS_DIR/assets/animated" -type f -delete
    cp -a "$TMP_DEPLOY/assets/animated/." "$QS_DIR/assets/animated/"

    mkdir -p "$QS_DIR/assets/icons" "$QS_DIR/assets"
    cp "$TMP_DEPLOY/assets/icons/"*.svg "$QS_DIR/assets/icons/"
    cp "$TMP_DEPLOY/assets/quotes.json" "$QS_DIR/assets/quotes.json"

    rm -rf "$TMP_DEPLOY"
    trap - EXIT INT TERM
fi

# The music card now uses a native QML rain-particle design; no Lottie runtime
# or downloaded animation assets are needed. Remove files left by older versions.
echo "==> Removing obsolete music dancer assets"
rm -f "$QS_DIR/ui/MusicDancer.qml" "$QS_DIR/ui/MusicDancerLottie.qml"
for dancer_index in 1 2 3 4 5; do
    rm -f "$QS_DIR/assets/music-dancers/dancer-$dancer_index.json"
done
rmdir "$QS_DIR/assets/music-dancers" >/dev/null 2>&1 || true

# Keep the lock-screen theme deployed even when the desktop config itself is
# already at the installed commit. This updates the GTKLock input and visual
# styling independently from the Quickshell UI deployment.
echo "==> Deploying A16EEN lock-screen theme"
mkdir -p "$LOCKSCREEN_DIR"
install -m644 "$ROOT_DIR/lockscreen/gtklock.css" "$LOCKSCREEN_DIR/gtklock.css"
install -m644 "$ROOT_DIR/lockscreen/gtklock.ui" "$LOCKSCREEN_DIR/gtklock.ui"
install -m644 "$ROOT_DIR/lockscreen/gtklock.ini" "$LOCKSCREEN_DIR/gtklock.ini"

# Restore the persistent A16EEN workspace registry after every deployment.
# Workspace creation/removal is handled live through Niri IPC; the source
# script recreates any user-defined named workspaces that are not currently
# present in the session.
if command -v niri >/dev/null 2>&1; then
    if ! bash "$ROOT_DIR/scripts/a16een-workspaces" apply; then
        echo "WARNING: could not restore the A16EEN workspace registry; keeping the deployed configuration." >&2
    fi
fi

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
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-lock" /usr/local/bin/a16een-lock
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-control" /usr/local/bin/a16een-control
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-clipboard" /usr/local/bin/a16een-clipboard
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-music" /usr/local/bin/a16een-music
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-widget-settings" /usr/local/bin/a16een-widget-settings
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-icon-theme" /usr/local/bin/a16een-icon-theme
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-navbar" /usr/local/bin/a16een-navbar
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-navbar-layout" /usr/local/bin/a16een-navbar-layout
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-navbar-content" /usr/local/bin/a16een-navbar-content
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-workspaces" /usr/local/bin/a16een-workspaces
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-focus-workspace" /usr/local/bin/a16een-focus-workspace
sudo install -Dm755 "$ROOT_DIR/scripts/a16een-workspace-preset" /usr/local/bin/a16een-workspace-preset

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

# Icon downloads are intentionally content-versioned. Unrelated A16EEN
# updates should not spend time re-fetching the same 113 Lucide SVGs.
ICON_SYNC_MARKER="$STATE_DIR/ui-icons-script-sha"
ICON_SYNC_SHA="$(sha256sum "$ROOT_DIR/scripts/a16een-icons" | awk '{print $1}')"
PREVIOUS_ICON_SYNC_SHA=""
if [ -f "$ICON_SYNC_MARKER" ]; then
    PREVIOUS_ICON_SYNC_SHA="$(cat "$ICON_SYNC_MARKER")"
fi
ICON_SYNCED=0

# The icon marker alone is not enough: an interrupted download or an older
# A16EEN revision can leave the runtime SVG library present but unusable.
# Check the workspace icons used by the live navbar and manager before trusting
# the marker. These files must be real SVGs and must not contain white strokes.
ICON_ASSETS_HEALTHY=1
for icon in house code globe messages-square sparkles music layers; do
    icon_file="$QS_DIR/assets/icons/$icon.svg"
    if [ ! -s "$icon_file" ] || ! grep -q '<svg' "$icon_file"        || grep -Eiq 'stroke="(white|#fff([0-9a-f]{2})?|#ffffff([0-9a-f]{2})?)"' "$icon_file"; then
        ICON_ASSETS_HEALTHY=0
        break
    fi
done

if [ "$ICON_SYNC_SHA" != "$PREVIOUS_ICON_SYNC_SHA" ] || [ "$ICON_ASSETS_HEALTHY" -ne 1 ]; then
    echo "==> Syncing A16EEN UI icons"
    if bash "$ROOT_DIR/scripts/a16een-icons"; then
        printf '%s\n' "$ICON_SYNC_SHA" > "$ICON_SYNC_MARKER"
        ICON_SYNCED=1
    else
        echo "WARNING: icon synchronization failed; using the bundled fallback SVGs." >&2
    fi
else
    echo "==> A16EEN UI icons already synced; skipping download."
fi

# Navbar SVGs are regenerated only when the navbar generator itself changes
# or when its generated state is missing. User-selected navbar settings remain
# in ~/.local/state/a16een/navbar.json and are applied by the manager.
NAVBAR_SYNC_MARKER="$STATE_DIR/navbar-script-sha"
# Runtime renderer revision invalidates stale generated navbar SVGs after
# a rendering-path repair, even when the generator source itself is unchanged.
NAVBAR_RUNTIME_REVISION="3"
NAVBAR_SCRIPT_HASH="$(sha256sum "$ROOT_DIR/scripts/a16een-navbar" | awk '{print $1}')"
NAVBAR_SYNC_SHA="$(printf '%s:%s' "$NAVBAR_RUNTIME_REVISION" "$NAVBAR_SCRIPT_HASH" | sha256sum | awk '{print $1}')"
PREVIOUS_NAVBAR_SYNC_SHA=""
if [ -f "$NAVBAR_SYNC_MARKER" ]; then
    PREVIOUS_NAVBAR_SYNC_SHA="$(cat "$NAVBAR_SYNC_MARKER")"
fi

# Never trust the ready marker when one of the live workspace SVGs is
# missing, invalid, or still rendered white. This catches stale files left by
# older navbar-renderer revisions.
# Gradient icons encode visible paint in stop-color values. Treat a gradient
# as unhealthy only when every stop is white; white-to-color gradients are valid.
NAVBAR_ASSETS_HEALTHY=1
for slot in home code web comms studio music; do
    generated="$STATE_DIR/navbar-icons/$slot.svg"
    GRADIENT_ALL_WHITE=0
    if grep -q 'stop-color=' "$generated" 2>/dev/null; then
        GRADIENT_ALL_WHITE=1
        while IFS= read -r stop; do
            value="${stop#stop-color=\"}"
            value="${value%\"}"
            case "$(printf '%s' "$value" | tr '[:lower:]' '[:upper:]')" in
                WHITE|'#FFFFFF'|'#FFFFFFFF') ;;
                *) GRADIENT_ALL_WHITE=0; break ;;
            esac
        done < <(grep -Eo 'stop-color="[^"]+"' "$generated" || true)
    fi

    if [ ! -s "$generated" ] || ! grep -q '<svg' "$generated" \
       || grep -Eiq 'stroke="(white|#fff([0-9a-f]{2})?|#ffffff([0-9a-f]{2})?)"' "$generated" \
       || [ "$GRADIENT_ALL_WHITE" -eq 1 ]; then
        NAVBAR_ASSETS_HEALTHY=0
        break
    fi
done

if [ "$NAVBAR_SYNC_SHA" != "$PREVIOUS_NAVBAR_SYNC_SHA" ] \
   || [ ! -f "$STATE_DIR/navbar-icons/ready" ] \
   || [ "$ICON_SYNCED" -eq 1 ] \
   || [ "$NAVBAR_ASSETS_HEALTHY" -ne 1 ]; then
    echo "==> Generating A16EEN navbar icons"
    if bash "$ROOT_DIR/scripts/a16een-navbar" apply; then
        printf '%s\n' "$NAVBAR_SYNC_SHA" > "$NAVBAR_SYNC_MARKER"
    else
        echo "WARNING: navbar icon generation failed; the navbar will use bundled fallbacks." >&2
    fi
else
    echo "==> A16EEN navbar icons already generated; skipping rebuild."
fi

# Restart only the Quickshell instance owned by A16EEN's supervisor.
# Quickshell can rewrite its argv after startup, so matching "-c $QS_DIR"
# against /proc/<pid>/cmdline is unreliable. The supervisor's child list is stable.
RESTARTED_SHELL=0
SUPERVISOR_PID=""

for cmdline in /proc/[0-9]*/cmdline; do
    [ -r "$cmdline" ] || continue
    PID="${cmdline#/proc/}"
    PID="${PID%/cmdline}"
    case "$PID" in
        ''|*[!0-9]*) continue ;;
    esac

    ARGS="$(tr '\0' '\n' < "$cmdline" 2>/dev/null || true)"
    if printf '%s\n' "$ARGS" | grep -Eq '(^|/)a16een-shell$'; then
        SUPERVISOR_PID="$PID"
        break
    fi
done

if [ -n "$SUPERVISOR_PID" ]; then
    CHILDREN="$(cat "/proc/$SUPERVISOR_PID/task/$SUPERVISOR_PID/children" 2>/dev/null || true)"
    for PID in $CHILDREN; do
        [ -r "/proc/$PID/exe" ] || continue
        EXECUTABLE="$(readlink "/proc/$PID/exe" 2>/dev/null || true)"
        COMMAND_NAME="${EXECUTABLE##*/}"
        case "$COMMAND_NAME" in
            qs|quickshell)
                if kill -TERM "$PID" 2>/dev/null; then
                    RESTARTED_SHELL=1
                    echo "==> Requested Quickshell restart through the A16EEN supervisor."
                    break
                fi
                ;;
        esac
    done
fi

# The supervisor normally restarts Quickshell after its process exits. If it is
# no longer running, bring it back only from an active A16EEN/Niri session.
SESSION_ACTIVE=0
[ -n "${NIRI_SOCKET:-}" ] && SESSION_ACTIVE=1
case ":${XDG_CURRENT_DESKTOP:-}:" in
    *:A16EEN:*) SESSION_ACTIVE=1 ;;
esac
if pgrep -u "$(id -u)" -x niri >/dev/null 2>&1; then
    SESSION_ACTIVE=1
fi

if { [ "$RESTARTED_SHELL" -eq 1 ] || [ "$SESSION_ACTIVE" -eq 1 ]; } &&
   ! pgrep -f '[a]16een-shell' >/dev/null 2>&1; then
    nohup /usr/local/bin/a16een-shell >/dev/null 2>&1 &
    echo "==> Started the A16EEN shell supervisor."
fi

echo
echo "╭──────────────────────────────────────────────╮"
echo "│           A16EEN installation complete       │"
echo "╰──────────────────────────────────────────────╯"
printf '%s\n' "$SOURCE_COMMIT" > "$STATE_DIR/installed-commit"

echo "Run 'a16een-update' whenever you want to check for updates."
echo "Built-in wallpapers: $QS_DIR/assets/wallpapers"
echo "Personal wallpapers: $USER_WALLPAPER_DIR"
echo "Personal animated wallpapers: $USER_WALLPAPER_DIR/animated"
