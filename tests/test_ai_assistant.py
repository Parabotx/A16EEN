#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import os
import stat
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest import mock

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
    state_home = Path(temp) / "state"
    env["XDG_STATE_HOME"] = str(state_home)

    status = invoke(env, "status")
    assert status["ok"] is True and status["configured"] is False
    assert status["provider"] == "gemini"
    assert status["gemini_configured"] is False and status["groq_configured"] is False
    selected = invoke(env, "provider", "set", "groq")
    assert selected["ok"] is True and selected["provider"] == "groq"
    provider_path = config / "a16een" / "ai" / "provider.json"
    assert stat.S_IMODE(provider_path.stat().st_mode) == 0o600
    assert invoke(env, "status")["provider"] == "groq"
    invoke(env, "provider", "set", "gemini")

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
    groq_saved = invoke(env, "key", "set-stdin", "groq", input_text="test-groq-key-123456\n")
    groq_key_path = config / "a16een" / "ai" / "groq-api-key"
    assert groq_saved["ok"] and groq_saved["provider"] == "groq"
    assert groq_key_path.read_text().strip() == "test-groq-key-123456"
    assert stat.S_IMODE(groq_key_path.stat().st_mode) == 0o600
    assert invoke(env, "status")["groq_configured"] is True
    assert invoke(env, "key", "remove", "groq")["configured"] is False
    assert not groq_key_path.exists()

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

    saved_chat = {
        "id": "chat-test-001",
        "title": "Diagnose Wi-Fi disconnects",
        "mode": "diagnose",
        "updated_at": 1700000000,
        "history": [{"role": "user", "parts": [{"text": "Diagnose Wi-Fi disconnects"}]}],
        "messages": [
            {"speaker": "user", "body": "Diagnose Wi-Fi disconnects"},
            {"speaker": "assistant", "body": "I will inspect the network state first."},
        ],
    }
    saved_result = invoke(env, "history", "save-stdin", input_text=json.dumps(saved_chat) + "\n")
    assert saved_result["ok"] is True and saved_result["active_id"] == "chat-test-001"
    history_file = state_home / "a16een" / "ai" / "conversations.json"
    assert history_file.exists()
    assert stat.S_IMODE(history_file.stat().st_mode) == 0o600
    assert stat.S_IMODE(history_file.parent.stat().st_mode) == 0o700

    loaded = invoke(env, "history", "list")
    assert loaded["ok"] is True and loaded["active_id"] == "chat-test-001"
    assert loaded["conversations"][0]["title"] == "Diagnose Wi-Fi disconnects"
    assert loaded["conversations"][0]["history"] == saved_chat["history"]
    assert loaded["conversations"][0]["messages"] == saved_chat["messages"]

    deleted = invoke(env, "history", "delete", "chat-test-001")
    assert deleted["ok"] is True and deleted["conversations"] == []

# Test mode-specific system prompts with a stubbed network boundary.
loader = importlib.machinery.SourceFileLoader("a16een_ai_under_test", str(SCRIPT))
spec = importlib.util.spec_from_loader("a16een_ai_under_test", loader)
assert spec is not None and spec.loader is not None
ai_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ai_module)


def test_mode(mode: str) -> str:
    captured = {}

    def fake_request(body):
        captured["body"] = body
        return {"parts": [{"text": "mode test response"}]}

    with mock.patch.object(ai_module, "request_gemini", side_effect=fake_request):
        result = ai_module.ask_gemini({
            "mode": mode,
            "history": [{"role": "user", "parts": [{"text": "Why is this happening?"}]}],
        })
    assert result["ok"] and result["mode"] == mode and result["text"] == "mode test response"
    return captured["body"]["systemInstruction"]["parts"][0]["text"]


normal_prompt = test_mode("normal")
explain_prompt = test_mode("explain")
diagnose_prompt = test_mode("diagnose")
assert "general-purpose assistant" in normal_prompt
assert "Prioritize explaining" in explain_prompt and "Do not change settings" in explain_prompt
assert "Treat problem reports as an investigation" in diagnose_prompt
assert "run_system_diagnostics" in diagnose_prompt and "diagnose_network" in diagnose_prompt
try:
    test_mode("surprise")
    raise AssertionError("Unknown assistant modes must be rejected.")
except ValueError:
    pass

# Groq compatibility: translate local typed functions into OpenAI-style tools
# and round-trip tool calls/results through A16EEN's provider-neutral history.
openai_tools = ai_module.groq_tool_definitions()
assert openai_tools[0]["type"] == "function"
assert openai_tools[0]["function"]["parameters"]["type"] == "object"
query_tool = next(item["function"] for item in openai_tools if item["function"]["name"] == "list_applications")
assert query_tool["parameters"]["properties"]["query"]["type"] == "string"
mixed_history = [
    {"role": "user", "parts": [{"text": "Turn the volume down"}]},
    {"role": "model", "parts": [{"text": "I'll adjust it."}, {"functionCall": {
        "name": "set_volume", "args": {"percent": 25}, "id": "call_test_01"
    }}]},
    {"role": "user", "parts": [{"functionResponse": {
        "name": "set_volume", "response": {"ok": True, "result": "Volume set"}, "id": "call_test_01"
    }}]},
]
groq_history = ai_module.groq_messages(mixed_history, "normal")
assert groq_history[1] == {"role": "user", "content": "Turn the volume down"}
assert groq_history[2]["role"] == "assistant" and groq_history[2]["tool_calls"][0]["id"] == "call_test_01"
assert groq_history[3]["role"] == "tool" and groq_history[3]["tool_call_id"] == "call_test_01"
groq_response = {"content": "I'll check that.", "tool_calls": [{
    "id": "call_groq_01", "type": "function",
    "function": {"name": "get_system_status", "arguments": "{}"},
}]}
with mock.patch.object(ai_module, "request_groq_completion", return_value=groq_response) as fake_groq:
    parsed_groq = ai_module.ask_groq({
        "mode": "normal",
        "history": [{"role": "user", "parts": [{"text": "Check system status"}]}],
    })
assert parsed_groq["ok"] and parsed_groq["provider"] == "groq"
assert parsed_groq["calls"][0]["id"] == "call_groq_01"
assert parsed_groq["calls"][0]["name"] == "get_system_status"
assert parsed_groq["text"] == "I'll check that."
assert fake_groq.call_args.args[0][1]["role"] == "user"

dock_qml = (ROOT / "quickshell/a16een/ui/Dock.qml").read_text()
assistant_qml = (ROOT / "quickshell/a16een/ui/AIAssistantPage.qml").read_text()
ai_icon = (ROOT / "quickshell/a16een/assets/icons/a16een-ai-sigil.svg").read_text()
tools_panel_qml = (ROOT / "quickshell/a16een/ui/ToolsPanel.qml").read_text()
navbar_script = (ROOT / "scripts/a16een-navbar").read_text()
popup_style = (ROOT / "quickshell/a16een/ui/PopupCardStyle.qml").read_text()
appearance_ui = (ROOT / "quickshell/a16een/ui/NavbarAppearancePage.qml").read_text()

# UI regressions: keep navbar shortcuts compact/icon-only, keep the AI tile
# separate from Gaming, and keep the AI popup's top-right control a real close action.
assert "readonly property int shortcutTileHeight: 26" in dock_qml
assert "readonly property int shortcutTileGap: 4" in dock_qml
assert "readonly property int shortcutRailGap: 24" in dock_qml
assert "id: gamingNavbarContainer" in dock_qml
assert 'iconName: "gamepad-2.svg"' in dock_qml
assert 'containerColorFor("gaming")' in dock_qml
assert "width: 24" in dock_qml and "height: 26" in dock_qml
assert 'x: root.navbarPosition === "right" ? parent.width - width - 8 : 8' in dock_qml
assert 'text: "AI"' not in dock_qml
assert 'fallbackPath: root.fallbackIconPath("a16een-ai-sigil.svg")' in dock_qml
assert 'aiNavbarMouse.containsMouse' not in dock_qml
assert 'configured_style="solid:#FFFFFF"' in navbar_script
assert 'if [[ "$slot" == "ai" && "$all_icon_on" != "true" && "$individual_icon" == "inherit" ]]' in navbar_script
assert 'return (id === "ai" || id === "gaming") ? "#15171A" : "#FFFFFF"' in dock_qml
assert '{ id: "gaming", name: "Gaming"' in appearance_ui
assert 'stroke="#FFFFFF"' in ai_icon
assert 'args == ["history", "list"]' in (ROOT / "scripts/a16een-ai").read_text()
assert 'command: ["a16een-ai", "history", "list"]' in assistant_qml
assert 'function openConversation' in assistant_qml
assert 'const firstPending = historySaveProcess.running ? 1 : 0' in assistant_qml
assert 'id: historyOverlay' in assistant_qml
assert 'property string assistantMode: "normal"' in assistant_qml
assert 'model: root.assistantModes' in assistant_qml
assert 'mode: root.assistantMode' in assistant_qml
assert 'Math.max(80, chatPanel.height - providerSelector.height - modeSelector.height' in assistant_qml
assert 'id: chatStatusRow' not in assistant_qml
assert 'progressPhrases[root.progressIndex]' not in assistant_qml
assert 'MODE_INSTRUCTIONS[mode]' in (ROOT / "scripts/a16een-ai").read_text()
assert 'viewBox="0 0 24 24"' in ai_icon and ai_icon.count("<path") >= 2
assert assistant_qml.index("id: errorMessage") < assistant_qml.index("id: composerSendButton")
assert 'text: "A16EEN AI"' not in assistant_qml
assert 'text: root.busy ? "WORKING" : "SEND  ↑"' not in assistant_qml
assert 'iconName: "lucide-settings.svg"' not in assistant_qml
assert 'Open chat history' in tools_panel_qml
assert 'containerId: root.page === "ai" ? "ai-assistant" : "quick-hub"' in tools_panel_qml
assert 'isolateAppearance: root.page === "ai"' in tools_panel_qml
assert 'id: aiHeaderSpacer' in tools_panel_qml
assert 'width: visible ? Math.max(0, parent.width - 28 - 25 - 25 - 25 - parent.spacing * 4) : 0' in tools_panel_qml
assert 'property bool isolateAppearance: false' in popup_style
assert 'root.isolateAppearance' in popup_style
assert 'root.selectedContainer.applyPopupCardColor === true' in popup_style
assert 'if (!root.isolateAppearance && root.allSettings.applyIconColor === true)' in popup_style
assert 'ai-assistant' in appearance_ui
assert 'text: bubble.fromUser ? "YOU" : "A16EEN AI"' in assistant_qml
assert 'color: bubble.fromUser ? "#F8FAFC" : root.textColor' in assistant_qml
assert 'color: "#D6AD60"' in assistant_qml
assert 'startNewConversation(true)' in tools_panel_qml
assert 'AI settings' in tools_panel_qml
assert 'function selectProvider(provider, fromChat)' in assistant_qml
assert 'providerSelector' in assistant_qml
assert 'id: typingIndicator' in assistant_qml
assert 'SequentialAnimation on opacity' in assistant_qml
assert 'TextMetrics {' in assistant_qml
assert 'REQUEST_TIMEOUT_SECONDS = 120' in (ROOT / "scripts/a16een-ai").read_text()
assert 'groq-api-key' in (ROOT / "scripts/a16een-ai").read_text()
assert 'api.groq.com/openai/v1/chat/completions' in (ROOT / "scripts/a16een-ai").read_text()
assert 'width: 1.5' in tools_panel_qml and 'height: 12' in tools_panel_qml
assert 'visible: root.page !== "ai"' in tools_panel_qml
assert 'root.closeRequested()' in tools_panel_qml and 'root.backRequested()' in tools_panel_qml
assert 'ai) configured_icon="a16een-ai-sigil.svg" ;;' in navbar_script
assert "migrate_ai_default_icon()" in navbar_script
assert "ai-navbar-sigil-v1" in navbar_script

print("A16EEN AI safety, key-storage, response modes, local history, and UI tests passed.")
