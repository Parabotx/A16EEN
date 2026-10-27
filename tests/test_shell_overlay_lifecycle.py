#!/usr/bin/env python3
"""Guard against optional overlay windows being instantiated at shell startup."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
shell = (ROOT / "quickshell/a16een/shell.qml").read_text(encoding="utf-8")
quick_window = (ROOT / "quickshell/a16een/ui/QuickToolsWindow.qml").read_text(encoding="utf-8")

assert "quickToolWindowComponent.createObject(root)" in shell
assert "batteryWarningPopupComponent.createObject(root)" in shell
assert "function ensureQuickToolWindow()" in shell
assert "function ensureBatteryWarningPopup()" in shell
assert "Qt.callLater(() => root.ensureQuickToolWindow())" in shell
assert "Qt.callLater(() => root.ensureBatteryWarningPopup())" in shell

# These roots must be declarations inside Components, not eagerly-created
# PanelWindows at ShellRoot level.
assert not re.search(r"(?m)^    QuickToolsWindow\s*\{", shell), (
    "QuickToolsWindow must not be instantiated directly by ShellRoot"
)
assert not re.search(r"(?m)^    BatteryWarningPopup\s*\{", shell), (
    "BatteryWarningPopup must not be instantiated directly by ShellRoot"
)

# PanelWindow.focusable is the public alias for the layershell keyboard-focus
# setting; keep one binding to prevent competing focus state.
assert "focusable: root.opened" in quick_window
assert "WlrLayershell.keyboardFocus: root.opened" not in quick_window

print("A16EEN overlay startup isolation checks passed.")
