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
snapshot="$("$SCRIPT" prepare-window)"
[[ -s "$snapshot" ]]
window_result="$("$SCRIPT" window "$snapshot")"
[[ -s "$window_result" ]]
[[ "$window_result" == "$HOME/Pictures/Screenshots/"* ]]
[[ ! -e "$snapshot" ]]

# Full-screen capture uses the same output-wait helper and must also succeed.
screen_result="$("$SCRIPT" screen)"
[[ -s "$screen_result" ]]

# Cancelling Niri's picker returns no window ID and must clean up the backdrop.
cancel_snapshot="$("$SCRIPT" prepare-window)"
if NIRI_PICK_CANCEL=1 "$SCRIPT" window "$cancel_snapshot" >/dev/null 2>"$SANDBOX/cancel.log"; then
    echo "Window cancellation unexpectedly succeeded." >&2
    exit 1
else
    status=$?
fi
[[ "$status" -eq 130 ]]
[[ ! -e "$cancel_snapshot" ]]

echo "Screenshot capture tests passed."
