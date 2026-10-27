#!/usr/bin/env python3
"""Regression tests for A16EEN Quick Tools; no network, package install, or real desktop required."""

import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "a16een-quick-tools"


def run(env, *args, input_text=None, check=False):
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        env=env,
        input=input_text,
        check=check,
        capture_output=True,
        text=True,
        timeout=30,
    )
    try:
        payload = json.loads(result.stdout.strip().splitlines()[-1])
    except (ValueError, IndexError):
        raise AssertionError(f"Expected JSON output for {args!r}: {result.stdout!r} {result.stderr!r}")
    return result, payload


with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    home = root / "home"
    state_home = root / "state"
    data_home = root / "data"
    system_data = root / "system-data"
    bin_dir = root / "bin"
    marker = root / "launch-marker"
    for folder in (home, data_home / "applications", system_data / "applications", bin_dir):
        folder.mkdir(parents=True, exist_ok=True)

    fake_app = bin_dir / "test-app"
    fake_app.write_text(
        "#!" + sys.executable + "\n"
        "import os\n"
        "from pathlib import Path\n"
        "Path(os.environ['APP_MARKER']).write_text('launched', encoding='utf-8')\n",
        encoding="utf-8",
    )
    fake_app.chmod(0o755)

    desktop_file = data_home / "applications" / "org.example.App.desktop"
    desktop_file.write_text(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=Quick Tools Test App\n"
        "Exec=test-app\n"
        "Icon=application-x-executable\n",
        encoding="utf-8",
    )

    fake_niri = bin_dir / "niri"
    fake_niri.write_text(
        "#!" + sys.executable + "\n"
        "import json, sys\n"
        "args = sys.argv[1:]\n"
        "windows = [{'id': 4, 'app_id': 'org.example.App', 'title': 'Test', 'workspace_id': 1, 'is_focused': True}]\n"
        "workspaces = [{'id': 1, 'name': 'code', 'is_focused': True}]\n"
        "if args[:3] == ['msg', '--json', 'windows']:\n"
        "    print(json.dumps({'Ok': {'Windows': windows}}))\n"
        "elif args[:3] == ['msg', '--json', 'workspaces']:\n"
        "    print(json.dumps({'Ok': {'Workspaces': workspaces}}))\n"
        "else:\n"
        "    print('{}')\n",
        encoding="utf-8",
    )
    fake_niri.chmod(0o755)

    env = os.environ.copy()
    env.update({
        "HOME": str(home),
        "XDG_STATE_HOME": str(state_home),
        "XDG_DATA_HOME": str(data_home),
        "XDG_DATA_DIRS": str(system_data),
        "PATH": str(bin_dir) + os.pathsep + env.get("PATH", ""),
        "APP_MARKER": str(marker),
    })

    # Application catalogue reads installed .desktop entries and marks locked apps.
    _, catalogue = run(env, "app-locker", "apps")
    app = next(item for item in catalogue["apps"] if item["desktop_id"] == "org.example.App.desktop")
    assert app["name"] == "Quick Tools Test App"
    assert app["locked"] is False

    # Passwords are sent over stdin and only a salted hash is persisted.
    result, protected = run(
        env,
        "app-locker",
        "protect",
        "org.example.App.desktop",
        "Quick Tools Test App",
        input_text="secure-password\nsecure-password\n",
    )
    assert result.returncode == 0, result.stderr
    assert protected["ok"] is True
    locker_file = state_home / "a16een" / "app-locker.json"
    locker_text = locker_file.read_text(encoding="utf-8")
    assert "secure-password" not in locker_text
    assert (locker_file.stat().st_mode & 0o777) == 0o600

    _, catalogue = run(env, "app-locker", "apps")
    app = next(item for item in catalogue["apps"] if item["desktop_id"] == "org.example.App.desktop")
    assert app["locked"] is True

    # Wrong passwords fail closed; the correct password permits a launcher-mediated open.
    result, rejected = run(
        env,
        "app-locker",
        "launch",
        "org.example.App.desktop",
        input_text="wrong-password\n",
    )
    assert result.returncode != 0
    assert rejected["ok"] is False and rejected["message"] == "Incorrect password."
    result, launched = run(
        env,
        "app-locker",
        "launch",
        "org.example.App.desktop",
        input_text="secure-password\n",
    )
    assert result.returncode == 0, result.stderr
    assert launched["ok"] is True
    deadline = time.time() + 3
    while time.time() < deadline and not marker.exists():
        time.sleep(0.05)
    assert marker.exists(), "unlocked application was not launched"

    # Removing protection also requires the existing password.
    result, removed = run(
        env,
        "app-locker",
        "unprotect",
        "org.example.App.desktop",
        input_text="secure-password\n",
    )
    assert result.returncode == 0
    assert removed["ok"] is True
    _, catalogue = run(env, "app-locker", "apps")
    app = next(item for item in catalogue["apps"] if item["desktop_id"] == "org.example.App.desktop")
    assert app["locked"] is False

    # Snapshot capture only records restorable desktop entries and uses user-only permissions.
    result, automatic = run(env, "snapshot", "auto")
    assert result.returncode == 0, result.stderr
    assert automatic["ok"] is True
    assert automatic["snapshot"]["app_count"] == 1
    snapshot_file = state_home / "a16een" / "session-snapshots.json"
    assert (snapshot_file.stat().st_mode & 0o777) == 0o600

    result, saved = run(env, "snapshot", "save", "Study setup")
    assert result.returncode == 0
    assert saved["ok"] is True
    manual_id = saved["snapshot"]["id"]

    _, listing = run(env, "snapshot", "list")
    assert listing["ok"] is True
    assert [item["id"] for item in listing["snapshots"]][0] == "auto"
    assert any(item["id"] == manual_id and item["name"] == "Study setup" for item in listing["snapshots"])

    # Restore starts the saved desktop app without invoking a shell command.
    marker.unlink(missing_ok=True)
    result, restored = run(env, "snapshot", "restore", "auto")
    assert result.returncode == 0, result.stderr
    assert restored["ok"] is True
    assert restored["launched"] == 1
    deadline = time.time() + 3
    while time.time() < deadline and not marker.exists():
        time.sleep(0.05)
    assert marker.exists(), "snapshot restore did not launch the saved application"

    result, deleted = run(env, "snapshot", "delete", manual_id)
    assert result.returncode == 0
    assert deleted["ok"] is True
    _, listing = run(env, "snapshot", "list")
    assert all(item["id"] != manual_id for item in listing["snapshots"])

print("A16EEN Quick Tools tests passed.")
