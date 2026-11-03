#!/usr/bin/env python3
"""Behavioral tests for A16EEN's optional wallpaper-adaptive theme helper."""

from __future__ import annotations

import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "scripts" / "a16een-wallpaper-theme"
TEMPLATE_ROOT = ROOT / "wallpaper-theme" / "templates"


class WallpaperThemeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.home_config = self.base / "config"
        self.home_state = self.base / "state"
        self.niri_config = self.home_config / "a16een" / "niri"
        self.bin_dir = self.base / "bin"
        self.niri_config.mkdir(parents=True)
        self.bin_dir.mkdir()
        self.wallpaper_light = self.base / "light.png"
        self.wallpaper_dark = self.base / "dark.png"
        self.wallpaper_light.write_bytes(b"fake-light-image")
        self.wallpaper_dark.write_bytes(b"fake-dark-image")

        self._write_stub(
            "magick",
            """#!/usr/bin/env python3
import os
print(os.environ.get("A16_TEST_BRIGHTNESS", "0.8"))
""",
        )
        self._write_stub(
            "matugen",
            r"""#!/usr/bin/env python3
import json
import re
import sys
import tomllib
from pathlib import Path

args = sys.argv[1:]
config_path = Path(args[args.index("-c") + 1])
config = tomllib.loads(config_path.read_text(encoding="utf-8"))
colors = {
    "background": "#101010",
    "foreground": "#f0f0f0",
    "surface": "#202020",
    "on_surface": "#f0f0f0",
    "surface_variant": "#303030",
    "on_surface_variant": "#e0e0e0",
    "primary": "#80a0d0",
    "on_primary": "#101010",
    "primary_container": "#304060",
    "on_primary_container": "#f0f0f0",
    "secondary": "#90b0a0",
    "secondary_container": "#304030",
    "tertiary": "#b090c0",
    "tertiary_container": "#503060",
    "error": "#d06060",
    "error_container": "#502020",
    "on_error": "#ffffff",
    "outline": "#8090a0",
    "outline_variant": "#505050",
    "surface_dim": "#181818",
    "surface_container": "#282828",
    "surface_container_low": "#222222",
    "on_tertiary_container": "#ffffff",
    "on_secondary_container": "#ffffff",
}
for item in config["templates"].values():
    source = Path(item["input_path"])
    destination = Path(item["output_path"])
    template = source.read_text(encoding="utf-8")

    def replace(match):
        token = match.group(1)
        key_match = re.search(r"colors[.]([a-z_]+)[.]", token)
        key = key_match.group(1) if key_match else "primary"
        value = colors.get(key, "#808080")
        return value[1:] if token.endswith("hex_stripped") else value

    output = re.sub(r"\{\{([^}]+)\}\}", replace, template)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(output, encoding="utf-8")
""",
        )
        self._write_stub(
            "niri",
            """#!/usr/bin/env python3
import os
import sys
if sys.argv[1:] == ["--version"]:
    print("niri 26.04.0")
else:
    with open(os.environ["A16_TEST_NIRI_LOG"], "a", encoding="utf-8") as stream:
        stream.write(" ".join(sys.argv[1:]) + "\\n")
""",
        )
        self._write_stub("kitty", "#!/bin/sh\nexit 0\n")

        self.env = os.environ.copy()
        self.env.update({
            "XDG_CONFIG_HOME": str(self.home_config),
            "XDG_STATE_HOME": str(self.home_state),
            "A16EEN_NIRI_CONFIG_DIR": str(self.niri_config),
            "A16_TEST_BRIGHTNESS": "0.8",
            "A16_TEST_NIRI_LOG": str(self.base / "niri.log"),
            "PATH": str(self.bin_dir) + os.pathsep + self.env.get("PATH", ""),
        })

        self.foot = self.home_config / "foot" / "foot.ini"
        self.foot.parent.mkdir(parents=True)
        self.foot.write_text("[main]\nfont=monospace\n", encoding="utf-8")
        self.foot.chmod(0o640)

        self.kitty = self.home_config / "kitty" / "kitty.conf"
        self.kitty.parent.mkdir(parents=True)
        self.kitty.write_text("font_size 12\n", encoding="utf-8")

        self.fuzzel = self.home_config / "fuzzel" / "fuzzel.ini"
        self.fuzzel.parent.mkdir(parents=True)
        self.fuzzel.write_text("[main]\nwidth=42\n", encoding="utf-8")

        self.gtk3 = self.home_config / "gtk-3.0" / "gtk.css"
        self.gtk4 = self.home_config / "gtk-4.0" / "gtk.css"
        self.gtk3.parent.mkdir(parents=True)
        self.gtk4.parent.mkdir(parents=True)
        self.gtk3.write_text("button { padding: 4px; }\n", encoding="utf-8")
        self.gtk4.write_text("label { font-weight: 500; }\n", encoding="utf-8")

        self.qt6 = self.home_config / "qt6ct" / "qt6ct.conf"
        self.qt6.parent.mkdir(parents=True)
        self.qt6.write_text(
            "[Appearance]\ncolor_scheme_path=/home/test/.config/qt6ct/colors/custom.conf\n\n"
            "[Fonts]\nfixed=monospace\n",
            encoding="utf-8",
        )

        self.niri_main = self.niri_config / "config.kdl"
        self.niri_main.write_text(
            'environment {\n    XDG_CURRENT_DESKTOP "A16EEN"\n}\n',
            encoding="utf-8",
        )
        for source in TEMPLATE_ROOT.glob("*"):
            self._copy_template(source)

        self.state_file = self.home_state / "a16een" / "wallpaper-theme.json"
        self.generated_niri = self.niri_config / "wallpaper-theme-generated.kdl"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def _write_stub(self, name: str, content: str) -> None:
        path = self.bin_dir / name
        path.write_text(content, encoding="utf-8")
        path.chmod(0o755)

    def _copy_template(self, source: Path) -> None:
        destination = self.home_config / "a16een" / "wallpaper-theme" / "templates" / source.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(source.read_bytes())

    def run_helper(self, *args: str, env: dict[str, str] | None = None, check: bool = True):
        return subprocess.run(
            [sys.executable, os.fspath(HELPER), *args],
            env=env or self.env,
            check=check,
            capture_output=True,
            text=True,
        )

    def status(self) -> dict:
        return json.loads(self.run_helper("status").stdout)

    def test_theme_is_disabled_by_default_and_status_initializes_state(self) -> None:
        status = self.status()
        self.assertFalse(status["enabled"])
        self.assertTrue(status["available"])
        self.assertFalse(status["paletteReady"])
        self.assertTrue(self.state_file.exists())
        self.assertFalse(json.loads(self.state_file.read_text(encoding="utf-8"))["enabled"])
        self.assertEqual(self.foot.read_text(encoding="utf-8"), "[main]\nfont=monospace\n")
        self.assertFalse(self.generated_niri.exists())

    def test_enable_light_switch_dark_apply_and_disable_restores_user_files(self) -> None:
        enabled = self.run_helper("enable", str(self.wallpaper_light))
        self.assertTrue(json.loads(enabled.stdout)["enabled"])

        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertTrue(state["enabled"])
        self.assertEqual(state["scheme"], "light")
        self.assertEqual(state["wallpaper"], str(self.wallpaper_light))
        self.assertEqual(state["qt6ctOriginal"], "/home/test/.config/qt6ct/colors/custom.conf")
        self.assertEqual(stat.S_IMODE(self.state_file.stat().st_mode), 0o600)
        matugen_config = (self.home_config / "a16een/wallpaper-theme/matugen.toml").read_text(encoding="utf-8")
        self.assertNotIn("reload_apps =", matugen_config)
        self.assertIn("set = false", matugen_config)
        self.assertIn('command = ""', matugen_config)

        foot = self.foot.read_text(encoding="utf-8")
        self.assertIn("font=monospace", foot)
        self.assertIn("A16EEN WALLPAPER THEME", foot)
        self.assertEqual(foot.count("[main]"), 1)
        self.assertIn("initial-color-theme=light", (self.home_config / "a16een/wallpaper-theme/generated/foot.ini").read_text(encoding="utf-8"))
        self.assertIn("alpha=0.97", (self.home_config / "a16een/wallpaper-theme/generated/foot.ini").read_text(encoding="utf-8"))

        kitty = self.kitty.read_text(encoding="utf-8")
        self.assertIn("font_size 12", kitty)
        self.assertIn("A16EEN WALLPAPER THEME", kitty)
        self.assertTrue((self.home_config / "fuzzel/fuzzel.ini").read_text(encoding="utf-8").find("A16EEN WALLPAPER THEME") >= 0)
        self.assertEqual(self.fuzzel.read_text(encoding="utf-8").count("[main]"), 1)
        self.assertIn("button { padding: 4px; }", self.gtk3.read_text(encoding="utf-8"))
        self.assertIn("label { font-weight: 500; }", self.gtk4.read_text(encoding="utf-8"))
        self.assertIn("a16een.conf", self.qt6.read_text(encoding="utf-8"))

        niri = self.generated_niri.read_text(encoding="utf-8")
        self.assertIn("opacity 0.96", niri)
        self.assertIn("background-effect", niri)
        self.assertIn("QT_QPA_PLATFORMTHEME", niri)

        self.env["A16_TEST_BRIGHTNESS"] = "0.1"
        self.run_helper("apply", str(self.wallpaper_dark))
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertTrue(state["enabled"])
        self.assertEqual(state["scheme"], "dark")
        self.assertEqual(state["qt6ctOriginal"], "/home/test/.config/qt6ct/colors/custom.conf")
        self.assertIn("opacity 0.92", self.generated_niri.read_text(encoding="utf-8"))
        self.assertIn(
            "initial-color-theme=dark",
            (self.home_config / "a16een/wallpaper-theme/generated/foot.ini").read_text(encoding="utf-8"),
        )
        self.assertIn(
            "alpha=0.93",
            (self.home_config / "a16een/wallpaper-theme/generated/foot.ini").read_text(encoding="utf-8"),
        )

        disabled = json.loads(self.run_helper("disable").stdout)
        self.assertFalse(disabled["enabled"])
        self.assertNotIn("A16EEN WALLPAPER THEME", self.foot.read_text(encoding="utf-8"))
        self.assertNotIn("A16EEN WALLPAPER THEME", self.kitty.read_text(encoding="utf-8"))
        self.assertNotIn("A16EEN WALLPAPER THEME", self.fuzzel.read_text(encoding="utf-8"))
        self.assertEqual(self.foot.read_text(encoding="utf-8"), "[main]\nfont=monospace\n")
        self.assertEqual(self.kitty.read_text(encoding="utf-8"), "font_size 12\n")
        self.assertEqual(self.fuzzel.read_text(encoding="utf-8"), "[main]\nwidth=42\n")
        self.assertEqual(self.gtk3.read_text(encoding="utf-8"), "button { padding: 4px; }\n")
        self.assertEqual(self.gtk4.read_text(encoding="utf-8"), "label { font-weight: 500; }\n")
        self.assertIn(
            "color_scheme_path=/home/test/.config/qt6ct/colors/custom.conf",
            self.qt6.read_text(encoding="utf-8"),
        )
        self.assertNotIn("opacity", self.generated_niri.read_text(encoding="utf-8"))

    def test_user_qt_platform_theme_is_not_overridden(self) -> None:
        custom_main = self.niri_main.read_text(encoding="utf-8").replace(
            'XDG_CURRENT_DESKTOP "A16EEN"',
            'XDG_CURRENT_DESKTOP "A16EEN"\n    QT_QPA_PLATFORMTHEME "qt5ct"',
        )
        self.niri_main.write_text(custom_main, encoding="utf-8")

        self.run_helper("enable", str(self.wallpaper_light))
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertFalse(state["qt6ctManaged"])
        self.assertNotIn("QT_QPA_PLATFORMTHEME", self.generated_niri.read_text(encoding="utf-8"))
        self.assertEqual(
            self.qt6.read_text(encoding="utf-8"),
            "[Appearance]\ncolor_scheme_path=/home/test/.config/qt6ct/colors/custom.conf\n\n[Fonts]\nfixed=monospace\n",
        )

    def test_existing_qt_environment_variable_is_not_overridden(self) -> None:
        custom_env = self.env.copy()
        custom_env["QT_QPA_PLATFORMTHEME"] = "qt5ct"
        self.run_helper("enable", str(self.wallpaper_light), env=custom_env)
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertFalse(state["qt6ctManaged"])
        self.assertNotIn("QT_QPA_PLATFORMTHEME", self.generated_niri.read_text(encoding="utf-8"))
        self.assertEqual(
            self.qt6.read_text(encoding="utf-8"),
            "[Appearance]\ncolor_scheme_path=/home/test/.config/qt6ct/colors/custom.conf\n\n"
            "[Fonts]\nfixed=monospace\n",
        )

    def test_failed_generation_does_not_leave_feature_enabled(self) -> None:
        missing = self.base / "missing.png"
        result = self.run_helper("enable", str(missing), check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.status()["enabled"])

    def test_files_created_by_helper_are_removed_cleanly_on_disable(self) -> None:
        self.foot.unlink()
        self.fuzzel.unlink()
        self.gtk3.unlink()
        self.gtk4.unlink()
        self.qt6.unlink()
        self.run_helper("enable", str(self.wallpaper_light))
        self.run_helper("disable")
        self.assertFalse(self.foot.exists())
        self.assertFalse(self.fuzzel.exists())
        self.assertFalse(self.gtk3.exists())
        self.assertFalse(self.gtk4.exists())
        self.assertFalse(self.qt6.exists())


if __name__ == "__main__":
    unittest.main()
