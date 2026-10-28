#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/home"
export HOME="$TMP/home"
export XDG_STATE_HOME="$TMP/state"
export NMCLI_LOG="$TMP/nmcli.log"
export PATH="$TMP/bin:$PATH"

cat > "$TMP/bin/nmcli" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
original_args="$*"
# Real nmcli has no --separator option. Fail loudly if the production helper
# regresses to the invalid command that caused the list to stay empty.
for arg in "$@"; do
    if [[ "$arg" == "--separator" ]]; then
        echo "nmcli: unknown option --separator" >&2
        exit 64
    fi
done
case "$original_args" in
    *"connection show"*) printf '%s' "${NMCLI_SAVED_PROFILES:-}"; exit 0 ;;
    *"connection up id "*) exit 0 ;;
    *"connection delete id "*) exit 0 ;;
esac
rescan="no"
while (($#)); do
    if [[ "$1" == "--rescan" && $# -ge 2 ]]; then
        rescan="$2"
        shift 2
    else
        shift
    fi
done
printf '%s\n' "$original_args" >> "$NMCLI_LOG"
case "$rescan" in
    yes) printf '%s' "${NMCLI_YES_OUTPUT:-}" ;;
    no)  printf '%s' "${NMCLI_NO_OUTPUT:-}" ;;
    *)   exit 2 ;;
esac
MOCK
chmod +x "$TMP/bin/nmcli"

assert_equal() {
    local description="$1" expected="$2" actual="$3"
    if [[ "$actual" != "$expected" ]]; then
        printf 'FAIL: %s\nExpected:\n%s\nActual:\n%s\n' \
            "$description" "$expected" "$actual" >&2
        exit 1
    fi
}

# nmcli terse output is colon-delimited; literal colons are escaped.
export NMCLI_SAVED_PROFILES="$(printf '%s\n' \
    'Home Wi-Fi:802-11-wireless:Home Wi-Fi' \
    'Office Saved Profile:802-11-wireless:Office\:Guest')
export NMCLI_NO_OUTPUT="$(printf '%s\n' \
    '*:Home Wi-Fi:90:WPA2' \
    ':Open Guest:62:' \
    ':Open Guest:62:' \
    ':Office\:Guest:77:WPA2' \
    ':Lobby|Guest:47:WPA2' \
    ':Cafe\\WiFi:55:WPA2')"
export NMCLI_YES_OUTPUT="$(printf '%s\n' \
    '*:Home Wi-Fi:93:WPA2' \
    ':Open Guest:68:' \
    ':Coffee Shop:54:WPA1 WPA2')"

# Cached results, duplicate removal, open networks, and special SSID characters.
actual="$(bash "$ROOT/scripts/a16een-control" wifi networks)"
expected="$(printf '%s\n' \
    'Home Wi-Fi|90|WPA2|*|yes' \
    'Open Guest|62|--||no' \
    'Office:Guest|77|WPA2||yes' \
    'Lobby\|Guest|47|WPA2||no' \
    'Cafe\\WiFi|55|WPA2||no')
assert_equal "cached Wi-Fi network formatting" "$expected" "$actual"
grep -Fq -- '-t -e yes -f IN-USE,SSID,SIGNAL,SECURITY' "$NMCLI_LOG"
if grep -Fq -- '--separator' "$NMCLI_LOG"; then
    echo "FAIL: unsupported nmcli --separator option was used" >&2
    exit 1
fi

# Explicit Refresh requests a fresh scan instead of reading only cached results.
actual="$(bash "$ROOT/scripts/a16een-control" wifi networks --scan)"
expected="$(printf '%s\n' \
    'Home Wi-Fi|93|WPA2|*|yes' \
    'Open Guest|68|--||no' \
    'Coffee Shop|54|WPA1 WPA2||no')"
assert_equal "fresh Wi-Fi scan formatting" "$expected" "$actual"
grep -Fq -- '--rescan yes' "$NMCLI_LOG"

# First launch with an empty cache falls back to a real scan.
export NMCLI_NO_OUTPUT=""
actual="$(bash "$ROOT/scripts/a16een-control" wifi networks)"
assert_equal "empty cache triggers first scan" "$expected" "$actual"

QML="$ROOT/quickshell/a16een/ui/ControlDetailSection.qml"
grep -Fq '["a16een-control", "wifi", "networks", "--scan"]' "$QML"
grep -Fq 'function splitWifiNetworkFields(raw)' "$QML"
grep -Fq 'root.refreshWifiNetworks(true)' "$QML"
if grep -Fq 'wifiScanRefresh' "$QML"; then
    echo "FAIL: old timer-based Wi-Fi rescan path is still present" >&2
    exit 1
fi

# Saved SSIDs are matched independently from their profile names, and saved
# credentials are reused through NetworkManager rather than prompting again.
grep -Fq 'NMCLI_SAVED_PROFILES' "$0"
: > "$NMCLI_LOG"
bash "$ROOT/scripts/a16een-control" wifi connect "Office:Guest" ""
grep -Fq 'connection up id Office Saved Profile' "$NMCLI_LOG"
if grep -Fq 'device wifi connect Office:Guest' "$NMCLI_LOG"; then
    echo "FAIL: saved Wi-Fi profile was bypassed for a password-based join" >&2
    exit 1
fi

: > "$NMCLI_LOG"
bash "$ROOT/scripts/a16een-control" wifi forget "Office:Guest"
grep -Fq 'connection delete id Office Saved Profile' "$NMCLI_LOG"

echo "Wi-Fi network discovery tests passed."
