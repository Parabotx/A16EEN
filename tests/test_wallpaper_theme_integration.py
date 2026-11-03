#!/usr/bin/env python3
"""Static deployment and Quickshell guards for wallpaper-adaptive appearance."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
helper = (ROOT / "scripts/a16een-wallpaper-theme").read_text(encoding="utf-8")
installer = (ROOT / "scripts/install.sh").read_text(encoding="utf-8")
niri = (ROOT / "niri/config.kdl").read_text(encoding="utf-8")
shell = (ROOT / "quickshell/a16een/shell.qml").read_text(encoding="utf-8")
theme = (ROOT / "quickshell/a16een/theme/WallpaperTheme.qml").read_text(encoding="utf-8")
ui = (ROOT / "quickshell/a16een/ui/TransparencySection.qml").read_text(encoding="utf-8")
popup = (ROOT / "quickshell/a16een/ui/PopupCardStyle.qml").read_text(encoding="utf-8")
navbar = (ROOT / "quickshell/a16een/ui/NavbarManager.qml").read_text(encoding="utf-8")
launcher = (ROOT / "quickshell/a16een/ui/Launcher.qml").read_text(encoding="utf-8")
command_center = (ROOT / "quickshell/a16een/ui/CommandCenter.qml").read_text(encoding="utf-8")
dock = (ROOT / "quickshell/a16een/ui/Dock.qml").read_text(encoding="utf-8")
clock = (ROOT / "quickshell/a16een/ui/EditorialTimeWidget.qml").read_text(encoding="utf-8")
media_card = (ROOT / "quickshell/a16een/ui/MediaCard.qml").read_text(encoding="utf-8")
quick_tools = (ROOT / "quickshell/a16een/ui/QuickToolsPage.qml").read_text(encoding="utf-8")
templates = ROOT / "wallpaper-theme/templates"

# The feature is explicitly opt-in and has one source-of-truth palette file.
assert '"enabled": False' in helper
assert '"set = false"' in helper
assert "command = \"\"" in helper
assert '"state": state_home() / "a16een/wallpaper-theme.json"' in helper
assert '"/a16een/wallpaper-theme.json"' in theme
assert "watchChanges: true" in theme
assert 'property bool wallpaperThemeAvailable: false' in ui
assert 'a16een-wallpaper-theme", "status"' in ui
assert 'root.setWallpaperTheme(!root.wallpaperThemeEnabled)' in ui

# A16EEN loads generated palette rules before its user-configurable opacity rules.
assert 'include "wallpaper-theme-generated.kdl"' in niri
assert "a16een-wallpaper-theme" in installer
assert "matugen" in installer
assert '"set = false"' in helper
assert "qt6ct" in installer
assert 'cp "$ROOT_DIR/quickshell/a16een/theme/"* "$TMP_DEPLOY/theme/"' in installer
assert 'cp "$TMP_DEPLOY/theme/"* "$QS_DIR/theme/"' in installer
assert 'install -m644 "$ROOT_DIR/wallpaper-theme/templates/"*' in installer

# Every wallpaper commit/selection refreshes the palette only when enabled;
# the helper's apply action is a no-op while disabled.
assert shell.count('Quickshell.execDetached(["a16een-wallpaper-theme", "apply", path])') >= 2
assert 'if not state["enabled"]:' in helper

# The shared Material palette is consumed by core Quickshell surfaces.
for content in (popup, navbar, launcher, command_center, ui, dock, clock, media_card, quick_tools):
    assert 'import "../theme" as AdaptiveTheme' in content
    assert "AdaptiveTheme.WallpaperTheme" in content

for name in ("palette.json", "foot.ini", "fuzzel.ini", "kitty.conf", "gtk.css", "qt6ct.conf"):
    assert (templates / name).is_file(), f"Missing wallpaper theme template: {name}"

# All relevant desktop integrations are generated and removable.
for token in (
    'p["foot"]',
    'p["fuzzel"]',
    'p["kitty"]',
    'p["gtk3"]',
    'p["gtk4"]',
    'p["qt6"]',
    'p["niri"]',
):
    assert token in helper

print("A16EEN wallpaper adaptive theme integration checks passed.")
