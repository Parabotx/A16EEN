#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_STATE_HOME="$TMP/state"
export A16EEN_NAVBAR_CMD="$TMP/bin/navbar"
export APPLY_LOG="$TMP/apply.log"
mkdir -p "$HOME" "$XDG_STATE_HOME/a16een" "$TMP/bin"

cat > "$XDG_STATE_HOME/a16een/navbar-appearance.json" <<'JSON'
{
  "all": {
    "visibilityControl": false,
    "visible": true,
    "applyContainerColor": false,
    "containerColor": "#15171A",
    "applyIconColor": false,
    "iconColor": "auto",
    "surfaceColor": "#FFFFFF"
  },
  "workspaces": {
    "home": {"visible": false, "iconColor": "#FFFFFF"},
    "code": {"visible": true, "iconColor": "#FFFFFF"}
  }
}
JSON
cat > "$A16EEN_NAVBAR_CMD" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$APPLY_LOG"
SH
chmod +x "$A16EEN_NAVBAR_CMD"
run() { bash "$ROOT/scripts/a16een-navbar-appearance" "$@"; }

run get >/dev/null
jq -e '.schemaVersion == 3 and (.workspaces == null)
    and (.containers | has("workspaces") and has("battery") and has("time") and has("utilities") and has("power")
        and has("quick-actions") and has("quick-hub"))
    and .containers.workspaces.visible == true
    and .containers.workspaces.iconColor == "inherit"
    and .containers["quick-actions"].visible == true
    and .containers["quick-hub"].visible == true' \
    "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null

run set all - containerColor '#E7E8EA'
run set all - applyContainerColor on
run set all - containerColor '#15171A'
run set all - applyIconColor on
run set all - iconColor auto
jq -e '.all.applyContainerColor == true and .all.containerColor == "#15171A"
    and .all.applyIconColor == true and .all.iconColor == "auto"' \
    "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null

run set all - visibilityControl on
if run set container workspaces visible off 2>/dev/null; then
    echo "Expected All visibility lock to block individual visibility." >&2; exit 1
fi
if run set container battery containerColor '#070B13' 2>/dev/null; then
    echo "Expected All background lock to block an individual background." >&2; exit 1
fi
if run set container power iconColor '#FFFFFF' 2>/dev/null; then
    echo "Expected All icon lock to block an individual icon color." >&2; exit 1
fi

run set all - visibilityControl off
run set all - applyContainerColor off
run set all - applyIconColor off
run set container workspaces visible off
run set container battery containerColor '#070B13'
run set container power iconColor auto
run set container quick-actions containerColor '#E7E8EA'
run set container quick-hub iconColor '#1D4ED8'
# Visibility writes must notify the shell without triggering the expensive icon generator.
apply_count_before="$(wc -l < "$APPLY_LOG")"
run set container battery visible off
apply_count_after="$(wc -l < "$APPLY_LOG")"
[[ "$apply_count_before" -eq "$apply_count_after" ]]
[[ -f "$XDG_STATE_HOME/a16een/navbar-icons/ready" ]]
jq -e '.containers.battery.visible == false' "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null
jq -e '.containers["quick-actions"].containerEnabled == true
    and .containers["quick-actions"].containerColor == "#E7E8EA"
    and .containers["quick-hub"].iconColor == "#1D4ED8"
    and .containers.workspaces.visible == false
    and .containers.battery.containerEnabled == true
    and .containers.battery.containerColor == "#070B13"
    and .containers.power.iconColor == "auto"' \
    "$XDG_STATE_HOME/a16een/navbar-appearance.json" >/dev/null

if run set container battery containerColor 'not-a-color' 2>/dev/null; then
    echo "Expected invalid colors to be rejected." >&2; exit 1
fi
if run set container missing visible off 2>/dev/null; then
    echo "Expected an unknown container to be rejected." >&2; exit 1
fi
grep -q "^apply$" "$APPLY_LOG"
grep -q "^apply-appearance power$" "$APPLY_LOG"
grep -q "^apply-appearance quick-actions$" "$APPLY_LOG"
grep -q "^apply-appearance quick-hub$" "$APPLY_LOG"
echo "Navbar container appearance tests passed."
