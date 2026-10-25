#!/usr/bin/env python3
import json
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "a16een-ai"

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
    assert names["get_desktop_context"] is False
    assert names["move_focused_column_to_workspace"] is False
    assert names["toggle_fullscreen"] is False
    assert names["toggle_floating"] is False
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

dock_qml = (ROOT / "quickshell/a16een/ui/Dock.qml").read_text()
assistant_qml = (ROOT / "quickshell/a16een/ui/AIAssistantPage.qml").read_text()
tools_panel_qml = (ROOT / "quickshell/a16een/ui/ToolsPanel.qml").read_text()
navbar_script = (ROOT / "scripts/a16een-navbar").read_text()

# UI regressions: keep the navbar tile compact/icon-only, the composer pinned
# to the bottom, and the AI popup's top-right control a real close action.
assert "readonly property int aiContainerHeight: 40" in dock_qml
assert "width: 32" in dock_qml and "height: 34" in dock_qml
assert 'text: "AI"' not in dock_qml
assert 'fallbackPath: root.fallbackIconPath("wand-sparkles.svg")' in dock_qml
assert 'Math.max(80, chatPanel.height - 79' in assistant_qml
assert assistant_qml.index("id: errorMessage") < assistant_qml.index("id: composerSendButton")
assert 'text: "A16EEN AI"' not in assistant_qml
assert 'text: root.busy ? "WORKING" : "SEND  ↑"' not in assistant_qml
assert 'iconName: "lucide-settings.svg"' in assistant_qml
assert 'visible: root.page !== "ai"' in tools_panel_qml
assert 'root.closeRequested()' in tools_panel_qml and 'root.backRequested()' in tools_panel_qml
assert 'ai) configured_icon="wand-sparkles.svg" ;;' in navbar_script
assert "migrate_ai_default_icon()" in navbar_script

print("A16EEN AI safety, key-storage, and UI regression tests passed.")
