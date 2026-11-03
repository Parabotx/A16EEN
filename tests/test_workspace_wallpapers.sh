#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_STATE_HOME="$TMP/state"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_DATA_HOME="$TMP/data"
mkdir -p "$HOME/Pictures/a16een"
WALLPAPER="$HOME/Pictures/a16een/Work Space.png"
: > "$WALLPAPER"
SCRIPT="$ROOT/scripts/a16een-wallpaper"

[[ "$(bash "$SCRIPT" workspace-list | jq -c 'keys')" == "[]" ]]
bash "$SCRIPT" workspace-set code "$WALLPAPER" >/dev/null
[[ "$(bash "$SCRIPT" workspace-path code)" == "$WALLPAPER" ]]
bash "$SCRIPT" catalog code | awk -F '\t' -v path="$WALLPAPER" '
    $4 == path && $5 == "1" { found=1 }
    END { exit !found }
'

# Removing a workspace assignment must leave the global wallpaper state alone.
GLOBAL_STATE="$XDG_STATE_HOME/a16een/wallpaper"
if [[ -e "$GLOBAL_STATE" ]]; then
    BEFORE="$(cat "$GLOBAL_STATE")"
else
    BEFORE=""
fi
bash "$SCRIPT" workspace-unset code >/dev/null
[[ -z "$(bash "$SCRIPT" workspace-path code)" ]]
if [[ -e "$GLOBAL_STATE" ]]; then
    [[ "$(cat "$GLOBAL_STATE")" == "$BEFORE" ]]
else
    [[ -z "$BEFORE" ]]
fi

if bash "$SCRIPT" workspace-set app-stash "$WALLPAPER" >/dev/null 2>&1; then
    echo "app-stash must not accept a workspace wallpaper assignment" >&2
    exit 1
fi

echo "Workspace wallpaper tests passed."
