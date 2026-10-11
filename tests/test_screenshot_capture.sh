#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

export HOME="$SANDBOX/home"
export XDG_CONFIG_HOME="$SANDBOX/config"
export XDG_STATE_HOME="$SANDBOX/state"
export XDG_RUNTIME_DIR="$SANDBOX/runtime"
MOCK_BIN="$SANDBOX/bin"
SCRIPT="$ROOT_DIR/scripts/a16een-screenshot"
mkdir -p "$HOME/Pictures/Screenshots" "$MOCK_BIN" "$XDG_RUNTIME_DIR"

cat > "$MOCK_BIN/niri" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "msg" && "${2:-}" == "--json" && "${3:-}" == "pick-window" ]]; then
    if [[ "${NIRI_PICK_CANCEL:-0}" == "1" ]]; then
        printf 'null\n'
    else
        printf '{"id": 42}\n'
    fi
    exit 0
fi

if [[ "${1:-}" == "msg" && "${2:-}" == "action" &&
      ( "${3:-}" == "screenshot-window" || "${3:-}" == "screenshot-screen" ) ]]; then
    output=""
    expect_path=0
    for arg in "$@"; do
        if [[ "$expect_path" == "1" ]]; then
            output="$arg"
            expect_path=0
        elif [[ "$arg" == "--path" ]]; then
            expect_path=1
        fi
    done
    [[ -n "$output" ]] || exit 2
    printf 'PNG fixture bytes\n' > "$output"
    exit 0
fi

echo "Unexpected niri invocation: $*" >&2
exit 2
MOCK

cat > "$MOCK_BIN/jq" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
input_file="${@: -1}"
if grep -q '"id"[[:space:]]*:' "$input_file"; then
    printf '42\n'
fi
MOCK

cat > "$MOCK_BIN/grim" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
output="${@: -1}"
printf 'PNG background fixture\n' > "$output"
MOCK

cat > "$MOCK_BIN/wl-copy" <<'MOCK'
#!/usr/bin/env bash
cat >/dev/null
MOCK

cat > "$MOCK_BIN/qs" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK

chmod +x "$MOCK_BIN/"*

export PATH="$MOCK_BIN:$PATH"

# Native window selection should capture the exact selected ID, wait for the
# screenshot file, save it, and remove the temporary blurred desktop image.
snapshot="$(bash "$SCRIPT" prepare-window)"
[[ -s "$snapshot" ]]
window_result="$(bash "$SCRIPT" window "$snapshot")"
[[ -s "$window_result" ]]
[[ "$window_result" == "$HOME/Pictures/Screenshots/"* ]]
[[ ! -e "$snapshot" ]]

# Free-area selection must prepare a frozen image and successfully crop it.
area_snapshot="$(bash "$SCRIPT" prepare-area)"
[[ -s "$area_snapshot" ]]
area_result="$(bash "$SCRIPT" area "$area_snapshot" 10 20 320 240)"
[[ -s "$area_result" ]]
[[ "$area_result" == "$HOME/Pictures/Screenshots/"* ]]
[[ ! -e "$area_snapshot" ]]

# The hover picker passes a specific Niri window ID directly. It must capture
# that window and remove the frozen desktop used for hover highlighting.
id_snapshot="$(bash "$SCRIPT" prepare-window)"
id_result="$(bash "$SCRIPT" window-id 42 "$id_snapshot")"
[[ -s "$id_result" ]]
[[ "$id_result" == "$HOME/Pictures/Screenshots/"* ]]
[[ ! -e "$id_snapshot" ]]

# Invalid IDs must be rejected instead of being passed into compositor IPC.
invalid_snapshot="$(bash "$SCRIPT" prepare-window)"
if bash "$SCRIPT" window-id not-a-window "$invalid_snapshot" >/dev/null 2>&1; then
    echo "Invalid window ID unexpectedly succeeded." >&2
    exit 1
else
    status=$?
fi
[[ "$status" -eq 2 ]]
[[ ! -e "$invalid_snapshot" ]]

# Full-screen capture uses the same output-wait helper and must also succeed.
screen_result="$(bash "$SCRIPT" screen)"
[[ -s "$screen_result" ]]

# Cancelling Niri's picker returns no window ID and must clean up the backdrop.
cancel_snapshot="$(bash "$SCRIPT" prepare-window)"
if NIRI_PICK_CANCEL=1 bash "$SCRIPT" window "$cancel_snapshot" >/dev/null 2>"$SANDBOX/cancel.log"; then
    echo "Window cancellation unexpectedly succeeded." >&2
    exit 1
else
    status=$?
fi
[[ "$status" -eq 130 ]]
[[ ! -e "$cancel_snapshot" ]]

echo "Screenshot capture tests passed."
