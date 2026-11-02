#!/usr/bin/env python3
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "scripts" / "a16een-transparency"


class TransparencyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.state_home = self.base / "state"
        self.config_dir = self.base / "niri"
        self.config_dir.mkdir()
        self.bin_dir = self.base / "bin"
        self.bin_dir.mkdir()
        self.windows_file = self.base / "windows.json"
        self.windows_file.write_text(json.dumps({
            "Ok": {
                "Windows": [
                    {
                        "id": 22,
                        "title": "Firefox — A16EEN",
                        "app_id": "org.mozilla.firefox",
                        "is_focused": True,
                    },
                    {
                        "id": 23,
                        "title": "Terminal",
                        "app_id": "foot",
                        "is_focused": False,
                    },
                ]
            }
        }), encoding="utf-8")
        niri = self.bin_dir / "niri"
        niri.write_text(
            "#!/bin/sh\ncat \"$A16_TEST_WINDOWS\"\n",
            encoding="utf-8",
        )
        niri.chmod(0o755)
        self.env = os.environ.copy()
        self.env.update({
            "XDG_STATE_HOME": str(self.state_home),
            "A16EEN_NIRI_CONFIG_DIR": str(self.config_dir),
            "A16_TEST_WINDOWS": str(self.windows_file),
            "PATH": str(self.bin_dir) + os.pathsep + self.env.get("PATH", ""),
        })
        self.rules_file = self.config_dir / "transparency.kdl"
        self.state_file = self.state_home / "a16een" / "transparency.json"

    def tearDown(self):
        self.temp.cleanup()

    def run_helper(self, *args, check=True):
        return subprocess.run(
            [str(HELPER), *args],
            env=self.env,
            check=check,
            capture_output=True,
            text=True,
        )

    def test_global_and_per_app_rules(self):
        self.run_helper("set-global", "on", "35")
        self.run_helper("set-app", "org.mozilla.firefox", "50")
        rules = self.rules_file.read_text(encoding="utf-8")
        self.assertIn("opacity 0.65", rules)
        self.assertIn(r'match app-id="^org\\.mozilla\\.firefox$"', rules)
        self.assertIn("opacity 0.50", rules)

    def test_navbar_rule_excludes_wallpaper(self):
        self.run_helper("set-navbar", "on", "12")
        rules = self.rules_file.read_text(encoding="utf-8")
        self.assertIn('match namespace="^a16een-"', rules)
        self.assertIn('exclude namespace="^a16een-wallpaper"', rules)
        self.assertIn("opacity 0.88", rules)

    def test_focused_shortcuts_change_transparency_in_five_percent_steps(self):
        self.run_helper("set-global", "on", "35")
        self.run_helper("increase-focused")
        rules = self.rules_file.read_text(encoding="utf-8")
        self.assertIn('title="^Firefox — A16EEN$"', rules)
        self.assertIn("is-focused=true", rules)
        self.assertIn("opacity 0.60", rules)

        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"][0]["percent"], 40)

        self.run_helper("increase-focused")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"][0]["percent"], 45)

        self.run_helper("decrease-focused")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"][0]["percent"], 40)
        self.assertIn("opacity 0.60", self.rules_file.read_text(encoding="utf-8"))

    def test_focused_shortcuts_inherit_per_app_rule(self):
        self.run_helper("set-app", "org.mozilla.firefox", "50")
        self.run_helper("decrease-focused")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"][0]["percent"], 45)
        self.assertIn("opacity 0.55", self.rules_file.read_text(encoding="utf-8"))

    def test_focused_shortcuts_clamp_at_ninety(self):
        self.run_helper("set-global", "on", "90")
        self.run_helper("increase-focused")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"], [])

        self.run_helper("decrease-focused")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"][0]["percent"], 85)

    def test_focused_decrease_at_zero_stays_opaque(self):
        self.run_helper("decrease-focused")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"], [])
        self.assertNotIn("is-focused=true", self.rules_file.read_text(encoding="utf-8"))

    def test_existing_focused_rules_load_without_legacy_percentage_setting(self):
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.state_file.write_text(json.dumps({
            "version": 1,
            "focusedOverrides": [{
                "app_id": "org.mozilla.firefox",
                "title": "Firefox — A16EEN",
                "percent": 30,
            }],
        }), encoding="utf-8")
        self.run_helper("increase-focused")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertEqual(state["focusedOverrides"][0]["percent"], 35)

    def test_get_returns_running_applications(self):
        result = json.loads(self.run_helper("get").stdout)
        self.assertTrue(result["niriAvailable"])
        self.assertEqual(result["windows"][0]["app_id"], "org.mozilla.firefox")
        self.assertTrue(result["windows"][0]["is_focused"])

    def test_rejects_unsafe_opacity_values(self):
        result = self.run_helper("set-global", "on", "91", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.rules_file.read_text(encoding="utf-8").strip().endswith("opacity 0.09"))

    def test_clear_app_removes_saved_override(self):
        self.run_helper("set-app", "foot", "40")
        self.run_helper("clear-app", "foot")
        state = json.loads(self.state_file.read_text(encoding="utf-8"))
        self.assertNotIn("foot", state["apps"])


if __name__ == "__main__":
    unittest.main()
