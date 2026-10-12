#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

export HOME="$TMP_ROOT/home"
export XDG_CONFIG_HOME="$TMP_ROOT/config"
export XDG_STATE_HOME="$TMP_ROOT/state"

mkdir -p "$HOME" "$XDG_CONFIG_HOME/mpv" "$XDG_CONFIG_HOME/a16een/mpv"
cp "$ROOT_DIR/mpv/a16een.conf" "$XDG_CONFIG_HOME/mpv/a16een.conf"
cp "$ROOT_DIR/mpv/a16een-osc.lua" "$XDG_CONFIG_HOME/a16een/mpv/a16een-osc.lua"
printf '# Existing user setting\nvo=gpu\n' > "$XDG_CONFIG_HOME/mpv/mpv.conf"

manager="$ROOT_DIR/scripts/a16een-mpv-theme"

bash "$manager" install
grep -Fq 'vo=gpu' "$XDG_CONFIG_HOME/mpv/mpv.conf"
grep -Fq 'include=~~/a16een.conf' "$XDG_CONFIG_HOME/mpv/mpv.conf"
grep -Fq 'A16EEN MPV theme: enabled' <(bash "$manager" status)

# Reinstall must not duplicate the managed include.
bash "$manager" install
test "$(grep -Fc 'include=~~/a16een.conf' "$XDG_CONFIG_HOME/mpv/mpv.conf")" -eq 1

bash "$manager" off
grep -Fq 'vo=gpu' "$XDG_CONFIG_HOME/mpv/mpv.conf"
! grep -Fq 'include=~~/a16een.conf' "$XDG_CONFIG_HOME/mpv/mpv.conf"
grep -Fq 'A16EEN MPV theme: disabled by user' <(bash "$manager" status)

# Updates must respect an explicit opt-out.
bash "$manager" install
! grep -Fq 'include=~~/a16een.conf' "$XDG_CONFIG_HOME/mpv/mpv.conf"

bash "$manager" on
test "$(grep -Fc 'include=~~/a16een.conf' "$XDG_CONFIG_HOME/mpv/mpv.conf")" -eq 1
grep -Fq 'vo=gpu' "$XDG_CONFIG_HOME/mpv/mpv.conf"
test -d "$XDG_STATE_HOME/a16een/backups"

echo 'MPV theme installation and user-config preservation tests passed.'
