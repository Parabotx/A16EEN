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

export NMCLI_NO_OUTPUT="$(printf '%s\n' \
    '*|Home Wi-Fi|90|WPA2' \
    '|Open Guest|62|' \
    '|Open Guest|62|')"
export NMCLI_YES_OUTPUT="$(printf '%s\n' \
    '*|Home Wi-Fi|93|WPA2' \
    '|Open Guest|68|' \
    '|Coffee Shop|54|WPA1 WPA2')"

# Cached discovery preserves the connected marker, de-duplicates identical
# rows, and encodes open networks so the UI won't ask for a password.
actual="$(bash "$ROOT/scripts/a16een-control" wifi networks)"
expected="$(printf '%s\n' 'Home Wi-Fi|90|WPA2|*' 'Open Guest|62|--|')"
assert_equal "cached Wi-Fi network formatting" "$expected" "$actual"
grep -Fq -- '--rescan no' "$NMCLI_LOG"

# Explicit Refresh must wait for a real scan rather than display the stale cache.
actual="$(bash "$ROOT/scripts/a16een-control" wifi networks --scan)"
expected="$(printf '%s\n' 'Home Wi-Fi|93|WPA2|*' 'Open Guest|68|--|' 'Coffee Shop|54|WPA1 WPA2|')"
assert_equal "fresh Wi-Fi scan formatting" "$expected" "$actual"
grep -Fq -- '--rescan yes' "$NMCLI_LOG"

# First launch can have an empty cache; the helper must automatically scan.
export NMCLI_NO_OUTPUT=""
actual="$(bash "$ROOT/scripts/a16een-control" wifi networks)"
expected="$(printf '%s\n' 'Home Wi-Fi|93|WPA2|*' 'Open Guest|68|--|' 'Coffee Shop|54|WPA1 WPA2|')"
assert_equal "empty cache triggers first scan" "$expected" "$actual"

QML="$ROOT/quickshell/a16een/ui/ControlDetailSection.qml"
grep -Fq '["a16een-control", "wifi", "networks", "--scan"]' "$QML"
grep -Fq 'root.refreshWifiNetworks(true)' "$QML"
if grep -Fq 'wifiScanRefresh' "$QML"; then
    echo "FAIL: old timer-based Wi-Fi rescan path is still present" >&2
    exit 1
fi

echo "Wi-Fi network discovery tests passed."
