from __future__ import annotations

import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "a16een-app-stash"
SPEC = importlib.util.spec_from_file_location("a16een_app_stash", SCRIPT)
APP_STASH = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(APP_STASH)


class AppStashTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        APP_STASH.STATE_HOME = root
        APP_STASH.STATE_DIR = root / "a16een"
        APP_STASH.STASH_FILE = APP_STASH.STATE_DIR / "app-stash.json"

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_store_is_private_and_round_trips(self) -> None:
        entries = [{
            "window_id": "42",
            "app_id": "firefox",
            "title": "Research",
            "restore_workspace": "web",
            "stashed_at": 123,
        }]
        APP_STASH.write_stash(entries)
        self.assertEqual(APP_STASH.read_stash(), entries)
        self.assertEqual(APP_STASH.STASH_FILE.stat().st_mode & 0o777, 0o600)
        self.assertEqual(APP_STASH.STATE_DIR.stat().st_mode & 0o777, 0o700)

    def test_hide_saves_window_and_moves_without_stealing_focus(self) -> None:
        live_windows = [{
            "id": 42, "app_id": "firefox", "title": "Research",
            "is_focused": True, "workspace_id": 3,
        }]
        workspace_list = [
            {"id": 3, "idx": 2, "name": "web", "is_focused": True},
            {"id": 9, "idx": 7, "name": "app-stash"},
        ]
        def fake_json(request: str):
            return live_windows if request == "windows" else workspace_list
        with patch.object(APP_STASH, "niri_json", side_effect=fake_json), \
             patch.object(APP_STASH, "run_niri") as run:
            self.assertEqual(APP_STASH.hide_window(), 0)
            run.assert_called_once_with([
                "action", "move-window-to-workspace", "--window-id", "42",
                "--focus", "false", "app-stash",
            ])
        self.assertEqual(APP_STASH.read_stash()[0]["restore_workspace"], "web")
        self.assertEqual(APP_STASH.read_stash()[0]["app_id"], "firefox")

    def test_restore_moves_then_focuses_the_original_workspace(self) -> None:
        APP_STASH.write_stash([{
            "window_id": "42", "app_id": "firefox", "title": "Research",
            "restore_workspace": "web", "stashed_at": 123,
        }])
        with patch.object(APP_STASH, "windows", return_value=[{"id": 42}]), \
             patch.object(APP_STASH, "run_niri") as run:
            self.assertEqual(APP_STASH.restore_window("42"), 0)
            self.assertEqual(run.call_args_list[0].args[0], [
                "action", "move-window-to-workspace", "--window-id", "42",
                "--focus", "false", "web",
            ])
            self.assertEqual(run.call_args_list[1].args[0], ["action", "focus-workspace", "web"])
            self.assertEqual(run.call_args_list[2].args[0], ["action", "focus-window", "--id", "42"])
        self.assertEqual(APP_STASH.read_stash(), [])

    def test_list_drops_closed_windows(self) -> None:
        APP_STASH.write_stash([{
            "window_id": "42", "app_id": "firefox", "title": "Research",
            "restore_workspace": "web", "stashed_at": 123,
        }])
        with patch.object(APP_STASH, "windows", return_value=[]), \
             patch.object(APP_STASH, "workspaces", return_value=[]):
            self.assertEqual(APP_STASH.list_stash(), 0)
        self.assertEqual(APP_STASH.read_stash(), [])


if __name__ == "__main__":
    unittest.main()
