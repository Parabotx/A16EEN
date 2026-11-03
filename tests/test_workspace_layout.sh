#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/state/a16een"
export XDG_STATE_HOME="$TMP/state"
export MOCK_NIRI_LOG="$TMP/niri-actions.log"
export MOCK_NIRI_WINDOWS="$TMP/windows.json"
cat > "$TMP/bin/niri" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "msg" && "$2" == "--json" && "$3" == "workspaces" ]]; then
  printf '%s\n' '[{"id":1,"name":"home","is_focused":true}]'
elif [[ "$1" == "msg" && "$2" == "--json" && "$3" == "windows" ]]; then
  cat "$MOCK_NIRI_WINDOWS"
elif [[ "$1" == "msg" && "$2" == "raw-request" ]]; then
  cat >> "$MOCK_NIRI_LOG"
else
  echo "Unexpected mock niri arguments: $*" >&2
  exit 2
fi
MOCK
chmod +x "$TMP/bin/niri"
export PATH="$TMP/bin:$PATH"
SCRIPT="$ROOT/scripts/a16een-workspace-layout"
cat > "$MOCK_NIRI_WINDOWS" <<'JSON'
[
  {"id":11,"workspace_id":1,"is_focused":true,"is_floating":false,"layout":{"pos_in_scrolling_layout":[1,1]}},
  {"id":12,"workspace_id":1,"is_focused":false,"is_floating":false,"layout":{"pos_in_scrolling_layout":[2,1]}}
]
JSON
[[ "$("$SCRIPT" get-profile home)" == "adaptive" ]]
"$SCRIPT" set-profile home adaptive >/dev/null
grep -q '"SetProportion":0.5' "$MOCK_NIRI_LOG"
grep -q '"FocusWindow":{"id":11}' "$MOCK_NIRI_LOG"
: > "$MOCK_NIRI_LOG"
"$SCRIPT" set-profile home canvas >/dev/null
grep -q '"MoveWindowToFloating":{"id":11}' "$MOCK_NIRI_LOG"
grep -q '"MoveWindowToFloating":{"id":12}' "$MOCK_NIRI_LOG"
: > "$MOCK_NIRI_LOG"
"$SCRIPT" set-profile home adaptive >/dev/null
grep -q '"MoveWindowToTiling":{"id":11}' "$MOCK_NIRI_LOG"
grep -q '"MoveWindowToTiling":{"id":12}' "$MOCK_NIRI_LOG"
cat > "$MOCK_NIRI_WINDOWS" <<'JSON'
[
  {"id":11,"workspace_id":1,"is_focused":true,"is_floating":false,"layout":{"pos_in_scrolling_layout":[1,1]}}
]
JSON
: > "$MOCK_NIRI_LOG"
"$SCRIPT" auto
grep -q '"SetProportion":1' "$MOCK_NIRI_LOG"
echo "Workspace layout tests passed."
