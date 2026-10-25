#!/usr/bin/env python3
import json
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "a16een-ai"

def invoke(env, *args, input_text=None, expected=0):
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        env=env, input=input_text, capture_output=True, text=True, timeout=10,
    )
    assert result.returncode == expected, (args, result.returncode, result.stdout, result.stderr)
    value = json.loads(result.stdout)
    return value

with tempfile.TemporaryDirectory() as temp:
    home = Path(temp) / "home"
    config = Path(temp) / "config"
    home.mkdir()
    config.mkdir()
    env = os.environ.copy()
    env["HOME"] = str(home)
    env["XDG_CONFIG_HOME"] = str(config)

    status = invoke(env, "status")
    assert status["ok"] is True and status["configured"] is False

    tools = invoke(env, "tools")
    assert tools["ok"] is True
    names = {item["name"]: item["requires_confirmation"] for item in tools["actions"]}
    assert names["random_wallpaper"] is False
    assert names["set_wallpaper"] is False
    assert names["reboot_system"] is True
    assert names["power_off_system"] is True
    assert names["suspend_system"] is True
    assert "run_shell_command" not in names

    saved = invoke(env, "key", "set-stdin", input_text="test-gemini-key-123456\n")
    key_path = config / "a16een" / "ai" / "gemini-api-key"
    assert saved["ok"] is True
    assert key_path.read_text().strip() == "test-gemini-key-123456"
    assert stat.S_IMODE(key_path.stat().st_mode) == 0o600
    assert stat.S_IMODE(key_path.parent.stat().st_mode) == 0o700

    invalid_key = invoke(env, "key", "set-stdin", input_text="bad\n", expected=1)
    assert invalid_key["ok"] is False

    # Confirmation-gated actions are denied by the executor unless the UI
    # explicitly sends the approval flag.
    denied = invoke(
        env, "execute",
        input_text=json.dumps({"name": "reboot_system", "args": {}, "approved": False}) + "\n"
    )
    assert denied["ok"] is False and denied["requires_confirmation"] is True

    unknown = invoke(
        env, "execute",
        input_text=json.dumps({"name": "run_shell_command", "args": {"cmd": "touch nope"}, "approved": True}) + "\n",
        expected=1,
    )
    assert unknown["ok"] is False

    removed = invoke(env, "key", "remove")
    assert removed["configured"] is False
    assert not key_path.exists()

print("A16EEN AI safety and key-storage tests passed.")
