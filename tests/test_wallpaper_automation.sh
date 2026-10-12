#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

export HOME="$TEST_ROOT/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

SCRIPT="$ROOT_DIR/scripts/a16een-wallpaper"
WALLPAPER_DIR="$XDG_CONFIG_HOME/a16een/quickshell/a16een/assets/wallpapers"
ANIMATED_DIR="$XDG_CONFIG_HOME/a16een/quickshell/a16een/assets/animated"
STATE_FILE="$XDG_STATE_HOME/a16een/wallpaper"
SETTINGS_FILE="$XDG_CONFIG_HOME/a16een/wallpaper-settings"

mkdir -p "$WALLPAPER_DIR" "$ANIMATED_DIR" "$(dirname "$STATE_FILE")"
printf 'fixture' > "$WALLPAPER_DIR/default.png"
printf 'fixture' > "$WALLPAPER_DIR/next.png"
printf 'fixture' > "$ANIMATED_DIR/loop.gif"

# Concurrent setting updates must not overwrite each other.
"$SCRIPT" settings set enabled 1 &
pid_enabled=$!
"$SCRIPT" settings set last_rotation 1 &
pid_rotation=$!
wait "$pid_enabled"
wait "$pid_rotation"
grep -Fxq 'enabled=1' "$SETTINGS_FILE"
grep -Fxq 'last_rotation=1' "$SETTINGS_FILE"

"$SCRIPT" settings set interval 5
"$SCRIPT" settings set mode sequential
"$SCRIPT" settings set source both
"$SCRIPT" settings set avoid_repeat 1
printf 'builtin\tdefault.png\n' > "$STATE_FILE"

# With two static wallpapers and repeat avoidance enabled, sequential rotation
# must choose the other image once the interval has elapsed.
"$SCRIPT" settings set last_rotation 1
"$SCRIPT" auto-check
IFS=$'\t' read -r current_source current_name < "$STATE_FILE"
[[ "$current_source" == "builtin" && "$current_name" == "next.png" ]]

# Selecting animated-only must actually filter to the animated catalog.
"$SCRIPT" set builtin default.png
"$SCRIPT" settings set source animated
"$SCRIPT" settings set mode random
"$SCRIPT" settings set last_rotation 1
"$SCRIPT" auto-check
IFS=$'\t' read -r current_source current_name < "$STATE_FILE"
[[ "$current_source" == "builtin-animated" && "$current_name" == "loop.gif" ]]

echo "Wallpaper automation tests passed."
