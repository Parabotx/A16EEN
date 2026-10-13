#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "a16een-widget-settings"


def run(env, *args):
    result = subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


with tempfile.TemporaryDirectory() as temp:
    env = os.environ.copy()
    env["XDG_STATE_HOME"] = temp

    initial = run(env, "load")
    assert initial["appShelfWidgetEnabled"] is False
    assert initial["appShelfShape"] == "capsule"
    assert initial["appShelfRotationEnabled"] is True
    assert initial["appShelfApps"] == []
    assert initial["musicWidgetBackgroundColor"] == "#EAF2F8"
    assert initial["musicWidgetBackgroundOpacity"] == 72

    payload = {
        "appShelfWidgetEnabled": True,
        "appShelfShape": "rounded",
        "appShelfRotationEnabled": False,
        "musicWidgetBackgroundColor": "#17324D",
        "musicWidgetBackgroundOpacity": 0,
        "appShelfApps": [
            {"desktopId": "firefox.desktop", "name": "Firefox", "icon": "firefox"},
            {"desktopId": "org.gnome.Nautilus.desktop", "name": "Files", "icon": "folder"},
            {"desktopId": "firefox.desktop", "name": "Duplicate", "icon": "broken"},
            {"desktopId": "../unsafe", "name": "Invalid", "icon": "bad"},
        ],
    }
    saved = run(env, "save", json.dumps(payload))
    assert saved["appShelfWidgetEnabled"] is True
    assert saved["appShelfShape"] == "rounded"
    assert saved["appShelfRotationEnabled"] is False
    assert saved["musicWidgetBackgroundColor"] == "#17324D"
    assert saved["musicWidgetBackgroundOpacity"] == 0
    assert [app["desktopId"] for app in saved["appShelfApps"]] == [
        "firefox.desktop", "org.gnome.Nautilus.desktop"
    ]

    # Later partial saves retain app selections while changing other options.
    second = run(env, "save", json.dumps({"timeShowSeconds": True}))
    assert second["timeShowSeconds"] is True
    assert second["appShelfWidgetEnabled"] is True
    assert second["appShelfRotationEnabled"] is False
    assert len(second["appShelfApps"]) == 2

    # Invalid shapes are ignored and cannot erase the saved choice.
    third = run(env, "save", json.dumps({
        "appShelfShape": "unknown",
        "musicWidgetBackgroundColor": "not-a-color",
        "musicWidgetBackgroundOpacity": 101,
    }))
    assert third["appShelfShape"] == "rounded"
    assert third["musicWidgetBackgroundColor"] == "#17324D"
    assert third["musicWidgetBackgroundOpacity"] == 0

    loaded = run(env, "load")
    assert loaded["appShelfApps"] == saved["appShelfApps"]

    # Circle is a supported persistent layout, not only a visual-only setting.
    circle_saved = run(env, "save", json.dumps({"appShelfShape": "circle"}))
    assert circle_saved["appShelfShape"] == "circle"
    circle_loaded = run(env, "load")
    assert circle_loaded["appShelfShape"] == "circle"
    assert circle_loaded["appShelfRotationEnabled"] is False

print("Widget settings persistence tests passed.")
