#!/usr/bin/env python3
"""Static integration guards for A16EEN lockscreen and PAM setup."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ui = (ROOT / "quickshell/a16een/ui/LockScreenSection.qml").read_text(encoding="utf-8")
shell = (ROOT / "quickshell/a16een/shell.qml").read_text(encoding="utf-8")
installer = (ROOT / "scripts/install.sh").read_text(encoding="utf-8")
pam = (ROOT / "lockscreen/gtklock.pam").read_text(encoding="utf-8")
lid = (ROOT / "systemd/99-a16een-lid.conf").read_text(encoding="utf-8")
auth = (ROOT / "scripts/a16een-lockscreen-auth").read_text(encoding="utf-8")

# All sign-in methods live in the existing /lockscreen Command Center page.
assert 'title: "Behavior"' in ui
assert 'title: "Dynamic key"' in ui
assert 'title: "Temporary"' in ui
assert "property bool timePasswordEnabled: false" in ui
assert "auth-add-temp" not in ui  # secrets are sent through Process stdin, not argv
assert 'command: ["a16een-lockscreen-auth", "add"]' in ui
assert "stdinEnabled: true" in ui
assert "Math.abs(root.timeOffsetMinutes)" in ui

# PAM checks A16EEN alternatives first, then keeps the system account stack.
assert "pam_exec.so expose_authtok quiet type=auth" in pam
assert "a16een-lockscreen-auth verify" in pam
assert "auth      include     system-auth" in pam
assert "account   include     system-auth" in pam
assert "password  include     system-auth" in pam
assert "session   include     system-auth" in pam
assert "PAM_RULE=" in installer
assert "/usr/local/bin/a16een-lockscreen-auth" in installer
assert "PAM_BACKUP" in installer

# Temporary credentials are hashed and atomically consumed; time codes are local HHMM.
assert "hashlib.scrypt" in auth
assert "hmac.compare_digest" in auth
assert "os.replace(temporary, path)" in auth
assert 'strftime("%I%M")' in auth
assert "uses_left" in auth

# Lid behavior and watcher recovery cover AC/docked laptops and transient swayidle exits.
for key in (
    "HandleLidSwitch=suspend",
    "HandleLidSwitchExternalPower=suspend",
    "HandleLidSwitchDocked=suspend",
):
    assert key in lid
assert "99-a16een-lid.conf" in installer
assert "systemctl kill --signal=HUP systemd-logind.service" in installer
assert "lockWatcherRecoveryTimer" in shell
assert "lockWatcherRecoveryTimer.restart()" in shell
assert 'args.push("before-sleep", "a16een-lockscreen prepare-sleep")' in shell
assert 'args.push("after-resume", "qs ipc call lock-screen request")' in shell

print("A16EEN lockscreen and PAM integration checks passed.")
