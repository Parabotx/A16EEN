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
assert "auth      include     login" in pam
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

# Native GTKLock modules are loaded only when their official Arch package files exist.
lock_script = (ROOT / "scripts/a16een-lock").read_text(encoding="utf-8")
lock_ini = (ROOT / "lockscreen/gtklock.ini").read_text(encoding="utf-8")
lock_css = (ROOT / "lockscreen/gtklock.css").read_text(encoding="utf-8")
action = (ROOT / "scripts/a16een-lockscreen-action").read_text(encoding="utf-8")
niri_config = (ROOT / "niri/config.kdl").read_text(encoding="utf-8")

assert "gtklock-playerctl-module" in installer
assert "gtklock-powerbar-module" in installer
assert "playerctl-module.so" in lock_script
assert "powerbar-module.so" in lock_script
assert "[playerctl]" in lock_ini and "position=under-clock" in lock_ini
assert "[powerbar]" in lock_ini and "show-labels=true" in lock_ini
assert "logout-command=/usr/local/bin/a16een-lockscreen-action logout" in lock_ini
assert "reboot-command=/usr/local/bin/a16een-lockscreen-action reboot" in lock_ini
assert "poweroff-command=/usr/local/bin/a16een-lockscreen-action poweroff" in lock_ini
assert "suspend-command=/usr/local/bin/a16een-lockscreen-action suspend" in lock_ini
assert "playerctl stop" in action
assert "niri msg action quit" in action
assert "systemctl reboot" in action
assert "systemctl poweroff" in action
assert "systemctl suspend" in action
assert "XF86AudioStop allow-when-locked=true" in niri_config
assert "#playerctl-box" in lock_css and "#powerbar-box" in lock_css

print("A16EEN lockscreen, PAM, media, and power integration checks passed.")
