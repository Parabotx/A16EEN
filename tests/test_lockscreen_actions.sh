#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ACTION="$ROOT_DIR/scripts/a16een-lockscreen-action"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"
cat >"$TMP_DIR/bin/systemctl" <<'STUB'
#!/usr/bin/env bash
printf 'systemctl:%s\n' "$*" >>"$A16EEN_ACTION_LOG"
STUB
cat >"$TMP_DIR/bin/niri" <<'STUB'
#!/usr/bin/env bash
printf 'niri:%s\n' "$*" >>"$A16EEN_ACTION_LOG"
STUB
cat >"$TMP_DIR/bin/playerctl" <<'STUB'
#!/usr/bin/env bash
printf 'playerctl:%s\n' "$*" >>"$A16EEN_ACTION_LOG"
STUB
chmod +x "$TMP_DIR/bin/"*

export PATH="$TMP_DIR/bin:$PATH"
export A16EEN_ACTION_LOG="$TMP_DIR/actions.log"
: >"$A16EEN_ACTION_LOG"

"$ACTION" logout
"$ACTION" reboot
"$ACTION" poweroff
"$ACTION" suspend
"$ACTION" media-stop

grep -Fxq 'niri:msg action quit' "$A16EEN_ACTION_LOG"
grep -Fxq 'systemctl:reboot' "$A16EEN_ACTION_LOG"
grep -Fxq 'systemctl:poweroff' "$A16EEN_ACTION_LOG"
grep -Fxq 'systemctl:suspend' "$A16EEN_ACTION_LOG"
grep -Fxq 'playerctl:stop' "$A16EEN_ACTION_LOG"

before="$(wc -l <"$A16EEN_ACTION_LOG")"
if "$ACTION" 'systemctl reboot' >/dev/null 2>&1; then
    echo "The lockscreen action helper accepted an arbitrary command." >&2
    exit 1
fi
after="$(wc -l <"$A16EEN_ACTION_LOG")"
[[ "$before" == "$after" ]]

echo "A16EEN lockscreen action allowlist tests passed."
