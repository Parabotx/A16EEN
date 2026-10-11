#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_STATE_HOME="$TMP/state"
export XDG_CONFIG_HOME="$TMP/config"
export A16EEN_NAVBAR_CMD="$TMP/bin/navbar"
export APPLY_LOG="$TMP/apply.log"
mkdir -p "$HOME" "$XDG_STATE_HOME/a16een" "$TMP/bin"

cat > "$XDG_STATE_HOME/a16een/workspaces.json" <<'JSON'
[
  {"id":"home","name":"HOME","icon":"house.svg"},
  {"id":"code","name":"CODE","icon":"code.svg"},
  {"id":"web","name":"WEB","icon":"globe.svg"}
]
JSON

cat > "$A16EEN_NAVBAR_CMD" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$APPLY_LOG"
SH
chmod +x "$A16EEN_NAVBAR_CMD"

run() {
    bash "$ROOT/scripts/a16een-navbar-appearance" "$@"
}

run get >/dev/null
jq -e '.all.surfaceColor == "#FFFFFF" and .workspaces.home.visible == true' \
    "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null

run set all - surfaceColor '#E7E8EA'
run set all - applyContainerColor on
run set all - containerColor '#15171A'
run set all - applyIconColor on
run set all - iconColor auto

jq -e '.all.surfaceColor == "#E7E8EA"
    and .all.applyContainerColor == true
    and .all.containerColor == "#15171A"
    and .all.applyIconColor == true
    and .all.iconColor == "auto"' \
    "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null

run set all - visibilityControl on
if run set workspace home visible off 2>/dev/null; then
    echo "Expected All visibility lock to block individual visibility." >&2
    exit 1
fi
if run set workspace home containerColor '#070B13' 2>/dev/null; then
    echo "Expected All container lock to block an individual background." >&2
    exit 1
fi
if run set workspace home iconColor '#FFFFFF' 2>/dev/null; then
    echo "Expected All icon lock to block an individual icon color." >&2
    exit 1
fi

run set all - visibilityControl off
run set all - visibilityControl on
run set all - visible off
jq -e '.all.visibilityControl == true and .all.visible == false' \
    "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null

run set all - visibilityControl off
run set all - applyContainerColor off
run set all - applyIconColor off
run set workspace home visible off
run set workspace home containerColor '#070B13'
run set workspace home iconColor auto

jq -e '.workspaces.home.visible == false
    and .workspaces.home.containerEnabled == true
    and .workspaces.home.containerColor == "#070B13"
    and .workspaces.home.iconColor == "auto"' \
    "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null

if run set workspace home containerColor 'not-a-color' 2>/dev/null; then
    echo "Expected invalid colors to be rejected." >&2
    exit 1
fi
if run set workspace missing visible off 2>/dev/null; then
    echo "Expected an unknown workspace to be rejected." >&2
    exit 1
fi

grep -q '^apply$' "$APPLY_LOG"
echo "Navbar appearance settings tests passed."
