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


def test_webm_preparation_keeps_alpha_and_caps_cache_at_four():
    with tempfile.TemporaryDirectory() as temp:
        home = Path(temp)
        bundled = home / ".config" / "a16een" / "quickshell" / "a16een" / "assets" / "music-elements"
        personal = home / "Pictures" / "a16een" / "music-elements"
        cache = home / ".cache" / "a16een" / "music-elements"
        bundled.mkdir(parents=True)
        personal.mkdir(parents=True)
        sources = []
        for index in range(6):
            path = bundled / f"sticker-{index}.webm"
            path.write_bytes(b"webm-source-" + bytes([index]))
            sources.append(path)

        module = load_music_module()
        module.BUILTIN_ELEMENTS_DIR = bundled
        module.USER_ELEMENTS_DIR = personal
        module.MUSIC_ELEMENTS_CACHE_DIR = cache
        commands = []

        def fake_ffmpeg(command, **kwargs):
            commands.append(command)
            vf_index = command.index("-vf")
            assert "format=rgba" in command[vf_index + 1]
            assert "fps=12" in command[vf_index + 1]
            assert command[command.index("-c:v") + 1] == "libwebp_anim"
            assert command[command.index("-loop") + 1] == "0"
            target = Path(command[-1])
            target.write_bytes(b"transparent-animated-webp")
            return SimpleNamespace(returncode=0, stderr="")

        urls = [path.as_uri() for path in sources]
        with (
            patch.object(module, "shutil_which", return_value="/usr/bin/ffmpeg"),
            patch.object(module.subprocess, "run", side_effect=fake_ffmpeg),
        ):
            first = module.prepare_music_elements(urls)
            assert len(first["items"]) == 4
            assert first["cacheLimit"] == 4
            assert len(list(cache.glob("*.webp"))) == 4
            assert {item["source"] for item in first["items"]} == set(urls[:4])
            assert all(Path(urllib_parse(item["prepared"])).is_file() for item in first["items"])

            # A new rolling window replaces old entries instead of growing the cache.
            second = module.prepare_music_elements(urls[2:])
            assert len(second["items"]) == 4
            assert len(list(cache.glob("*.webp"))) == 4
            assert {item["source"] for item in second["items"]} == set(urls[2:])

        assert len(commands) == 6


def urllib_parse(url):
    from urllib.parse import unquote, urlparse

    return unquote(urlparse(url).path)


def test_music_artwork_occlusion_only_matches_current_workspace():
    module = load_music_module()
    windows = [
        {
            "workspace_id": 7,
            "is_focused": False,
            "layout": {
                "tile_pos_in_workspace_view": [70, 80],
                "tile_size": [180, 120],
            },
        },
        {
            "workspace_id": 8,
            "is_focused": True,
            "layout": {
                "tile_pos_in_workspace_view": [0, 0],
                "tile_size": [1920, 1080],
            },
        },
    ]
    assert module.active_window_covers_region(windows, 7, (100, 100, 50, 40))
    assert not module.active_window_covers_region(windows, 7, (400, 300, 50, 40))
    assert not module.active_window_covers_region(windows, 7, (190, 190, 20, 20))


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
