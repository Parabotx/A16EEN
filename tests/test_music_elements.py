#!/usr/bin/env python3
"""Regression tests for WebP/WebM artwork discovery and MPV startup locking."""

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "a16een-music"


def load_music_module():
    from importlib.machinery import SourceFileLoader

    loader = SourceFileLoader("a16een_music_test_module", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def test_webp_and_webm_elements_include_bundled_and_personal_files():
    with tempfile.TemporaryDirectory() as temp:
        home = Path(temp)
        personal = home / "Pictures" / "a16een" / "music-elements"
        personal_nested = personal / "Telegram" / "stickers"
        personal_nested.mkdir(parents=True)

        bundled = home / ".config" / "a16een" / "quickshell" / "a16een" / "assets" / "music-elements"
        bundled_nested = bundled / "default-pack"
        bundled_nested.mkdir(parents=True)

        (bundled / "bundled-first.webp").write_bytes(b"webp")
        (bundled_nested / "bundled-nested.WEBP").write_bytes(b"webp")
        (bundled_nested / "file_3831964.webm").write_bytes(b"webm")
        (personal / "z-last.WEBP").write_bytes(b"webp")
        (personal / "a-first.webp").write_bytes(b"webp")
        (personal_nested / "middle.webp").write_bytes(b"webp")
        (personal_nested / "telegram-sticker.WEBM").write_bytes(b"webm")
        (personal / "not-art.png").write_bytes(b"png")
        (personal / "folder.webp").mkdir()

        env = os.environ.copy()
        env["HOME"] = str(home)
        env["XDG_RUNTIME_DIR"] = str(home / "runtime")
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "elements"],
            env=env,
            check=True,
            capture_output=True,
            text=True,
            timeout=5,
        )
        payload = json.loads(result.stdout)
        expected_bundled = sorted(
            (path.resolve().as_uri()
             for path in bundled.rglob("*")
             if path.is_file() and path.suffix.casefold() in {".webp", ".webm"}),
            key=str.casefold,
        )
        expected_personal = sorted(
            (path.resolve().as_uri()
             for path in personal.rglob("*")
             if path.is_file() and path.suffix.casefold() in {".webp", ".webm"}),
            key=str.casefold,
        )
        assert payload["directory"] == str(personal)
        assert payload["builtInDirectory"] == str(bundled)
        assert payload["elements"] == expected_bundled + expected_personal
        assert all(source.startswith("file://") for source in payload["elements"])


def test_concurrent_play_requests_start_only_one_mpv_process():
    with tempfile.TemporaryDirectory() as temp:
        home = Path(temp)
        music_dir = home / "Music"
        runtime_dir = home / "runtime"
        music_dir.mkdir()
        runtime_dir.mkdir()
        track = music_dir / "test-song.mp3"
        track.write_bytes(b"audio")

        module = load_music_module()
        module.MUSIC_DIR = music_dir
        module.RUNTIME_DIR = runtime_dir
        module.SOCKET_PATH = runtime_dir / "a16een-music.sock"
        module.START_LOCK_PATH = runtime_dir / "a16een-music-start.lock"
        module.PLAYER_PID_PATH = runtime_dir / "a16een-music.pid"

        player_started = threading.Event()
        launch_calls = []
        launch_lock = threading.Lock()
        outcomes = []
        start_barrier = threading.Barrier(3)

        def fake_send_command(command, wait_for_response=False, timeout=0.65):
            return {"ok": True} if player_started.is_set() else None

        def fake_popen(*args, **kwargs):
            with launch_lock:
                launch_calls.append(args)
            # Simulate a slow first startup so both callers have time to race.
            time.sleep(0.15)
            player_started.set()
            return SimpleNamespace(pid=os.getpid())

        def play():
            start_barrier.wait()
            outcomes.append(module.play_path(str(track)))

        threads = [threading.Thread(target=play) for _ in range(2)]
        with (
            patch.object(module, "send_command", side_effect=fake_send_command),
            patch.object(module, "shutil_which", return_value=True),
            patch.object(module.subprocess, "Popen", side_effect=fake_popen),
        ):
            for thread in threads:
                thread.start()
            start_barrier.wait()
            for thread in threads:
                thread.join(timeout=8)

        assert all(not thread.is_alive() for thread in threads), "player startup lock deadlocked"
        assert len(launch_calls) == 1, f"expected one MPV process, got {len(launch_calls)}"
        assert len(outcomes) == 2
        assert all(outcome.get("ok") is True for outcome in outcomes)


if __name__ == "__main__":
    test_webp_and_webm_elements_include_bundled_and_personal_files()
    test_concurrent_play_requests_start_only_one_mpv_process()
    print("Music WebP/WebM discovery and startup-lock tests passed.")
