#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMP_DIR=$(mktemp -d)
SCAN_PID=""

cleanup() {
    if [[ "${SCAN_PID" =~ ^[0-9]+$ ]]; then
        kill "$SCAN_PID" >/dev/null 2>&1 || true
    fi
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

mkdir -p "$TMP_DIR/bin" "$TMP_DIR/state"
export MOCK_BT_LOG="$TMP_DIR/bluetoothctl.log"

cat > "$TMP_DIR/bin/bluetoothctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_BT_LOG"

if [[ "${1:-" == "--timeout" && "${3:-" == "scan" && "${4:-" == "on" ]]; then
    sleep 4
    exit 0
fi

case "${1:-" in
    show)
        printf 'Controller 00:11:22:33:44:55 (public)\n\tPowered: yes\n'
        ;;
    devices)
        if [[ "${2:-" == "Paired" ]]; then
            printf 'Device AA:BB:CC:DD:EE:01 Existing Headphones\n'
        else
            printf 'Device AA:BB:CC:DD:EE:01 Existing Headphones\n'
            printf 'Device AA:BB:CC:DD:EE:02 Newly Found Speaker\n'
        fi
        ;;
    info)
        case "${2:-" in
            AA:BB:CC:DD:EE:01)
                printf 'Device AA:BB:CC:DD:EE:01\n\tPaired: yes\n\tTrusted: yes\n\tConnected: yes\n'
                ;;
            AA:BB:CC:DD:EE:02)
                printf 'Device AA:BB:CC:DD:EE:02\n\tPaired: no\n\tTrusted: no\n\tConnected: no\n'
                ;;
        esac
        ;;
    *)
        exit 0
        ;;
esac
MOCK
chmod +x "$TMP_DIR/bin/bluetoothctl"

output=$(PATH="$TMP_DIR/bin:$PATH" XDG_STATE_HOME="$TMP_DIR/state" \
    "$ROOT_DIR/scripts/a16een-control" bluetooth detail)
grep -Fq 'state=on' <<< "$output"
grep -Fq 'AA:BB:CC:DD:EE:01|Existing Headphones|yes|yes|yes' <<< "$output"
grep -Fq 'AA:BB:CC:DD:EE:02|Newly Found Speaker|no|no|no' <<< "$output"

PATH="$TMP_DIR/bin:$PATH" XDG_STATE_HOME="$TMP_DIR/state" \
    "$ROOT_DIR/scripts/a16een-control" bluetooth scan
PID_FILE="$TMP_DIR/state/a16een/bluetooth-scan.pid"
[[ -s "$PID_FILE" ]]
SCAN_PID=$(cat "$PID_FILE")

for _ in {1..20}; do
    grep -Fq -- '--timeout 12 scan on' "$MOCK_BT_LOG" && break
    sleep 0.05
done
grep -Fq -- '--timeout 12 scan on' "$MOCK_BT_LOG"
kill "$SCAN_PID" >/dev/null 2>&1 || true
SCAN_PID=""

echo "Bluetooth discovery checks passed."
