#!/usr/bin/env python3
"""Tests for A16EEN's optional GTKLock credentials."""
import datetime as dt
import json
import os
import pwd
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "scripts" / "a16een-lockscreen-auth"


def run(env, *args, input_text=None, expect=0):
    result = subprocess.run(
        [sys.executable, str(HELPER), *args],
        env=env,
        input=input_text,
        text=True,
        capture_output=True,
    )
    assert result.returncode == expect, (args, result.stdout, result.stderr)
    return result


with tempfile.TemporaryDirectory() as temp:
    env = os.environ.copy()
    env["A16EEN_LOCKSCREEN_STATE_HOME"] = str(Path(temp) / "state")
    env["PAM_USER"] = pwd.getpwuid(os.getuid()).pw_name

    initial = json.loads(run(env, "get").stdout)
    assert initial["timeEnabled"] is False
    assert initial["timeOffsetMinutes"] == -20
    assert initial["temporaryCodes"] == []

    # The example in the feature brief: 11:53 minus 20 minutes = 11:33.
    now = dt.datetime(2026, 11, 2, 11, 53, tzinfo=dt.timezone.utc)
    import runpy
    module = runpy.run_path(str(HELPER), run_name="a16een_lockscreen_auth")
    assert module["time_code"](-20, now) == "1133"
    assert module["time_code"](-20, dt.datetime(2026, 11, 2, 11, 13, tzinfo=dt.timezone.utc)) == "1053"
    assert module["time_code"](0, dt.datetime(2026, 11, 2, 0, 5, tzinfo=dt.timezone.utc)) == "1205"

    run(env, "set-time", "true", "-20")
    changed = json.loads(run(env, "get").stdout)
    assert changed["timeEnabled"] is True
    assert changed["timeOffsetMinutes"] == -20

    # Temporary credentials are written via stdin, never command-line arguments.
    payload = json.dumps({"label": "Guest access", "password": "Guest-Access-42", "uses": 3})
    created = json.loads(run(env, "add", input_text=payload + "\n").stdout)
    assert len(created["temporaryCodes"]) == 1
    credential = created["temporaryCodes"][0]
    assert credential["label"] == "Guest access"
    assert credential["usesLeft"] == 3
    assert "digest" not in json.dumps(created)
    assert "Guest-Access-42" not in json.dumps(created)

    for remaining in (2, 1, 0):
        run(env, "verify", input_text="Guest-Access-42\n", expect=0)
        updated = json.loads(run(env, "get").stdout)
        assert updated["temporaryCodes"][0]["usesLeft"] == remaining

    # Expired one-time credentials are rejected.
    run(env, "verify", input_text="Guest-Access-42\n", expect=1)

    # One-use codes are consumed exactly once.
    created_once = json.loads(run(env, "add", input_text=json.dumps({
        "label": "One-time", "password": "One-Time-Code-7", "uses": 1
    }) + "\n").stdout)
    once_id = created_once["temporaryCodes"][-1]["id"]
    run(env, "verify", input_text="One-Time-Code-7\n", expect=0)
    run(env, "verify", input_text="One-Time-Code-7\n", expect=1)

    run(env, "remove", once_id)
    removed = json.loads(run(env, "get").stdout)
    assert all(item["id"] != once_id for item in removed["temporaryCodes"])

    # Invalid settings and weak temporary passwords are rejected.
    run(env, "set-time", "true", "721", expect=1)
    run(env, "add", input_text=json.dumps({
        "label": "Weak", "password": "123", "uses": 1
    }) + "\n", expect=1)

    state_path = Path(env["A16EEN_LOCKSCREEN_STATE_HOME"]) / "a16een" / "lockscreen-auth.json"
    assert state_path.stat().st_mode & 0o777 == 0o600
    assert state_path.parent.stat().st_mode & 0o777 == 0o700

print("A16EEN lockscreen authentication tests passed.")
