from __future__ import annotations

import importlib.machinery
import importlib.util
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "a16een-data-meter"
LOADER = importlib.machinery.SourceFileLoader("a16een_data_meter", str(SCRIPT))
SPEC = importlib.util.spec_from_loader("a16een_data_meter", LOADER)
METER = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(METER)


def sample(rx: int, tx: int, name: str = "wlp2s0") -> dict:
    return {
        "name": name,
        "type": "Wi-Fi",
        "connection": "Home Wi-Fi",
        "is_default": True,
        "rx": rx,
        "tx": tx,
    }


class DataMeterTests(unittest.TestCase):
    def test_first_sample_is_baseline(self):
        state, output = METER.update_usage({}, [sample(1000, 500)], "2026-10-10", 10000)
        self.assertEqual(output["today_download_bytes"], 0)
        self.assertEqual(output["month_download_bytes"], 0)
        self.assertEqual(output["connection_name"], "Home Wi-Fi")
        self.assertEqual(state["date"], "2026-10-10")
        self.assertEqual(state["month"], "2026-10")

    def test_daily_usage_and_speed(self):
        state, _ = METER.update_usage({}, [sample(1000, 500)], "2026-10-10", 10000)
        _, output = METER.update_usage(state, [sample(7000, 1500)], "2026-10-10", 12000)
        self.assertEqual(output["today_download_bytes"], 6000)
        self.assertEqual(output["today_upload_bytes"], 1000)
        self.assertEqual(output["month_download_bytes"], 6000)
        self.assertEqual(output["month_upload_bytes"], 1000)
        self.assertEqual(output["down_bps"], 3000)
        self.assertEqual(output["up_bps"], 500)

    def test_monthly_totals_continue_across_days(self):
        state, _ = METER.update_usage({}, [sample(1000, 500)], "2026-10-10", 10000)
        state, _ = METER.update_usage(state, [sample(7000, 1500)], "2026-10-10", 12000)
        _, output = METER.update_usage(state, [sample(9000, 1800)], "2026-10-11", 14000)
        self.assertEqual(output["today_download_bytes"], 2000)
        self.assertEqual(output["today_upload_bytes"], 300)
        self.assertEqual(output["month_download_bytes"], 8000)
        self.assertEqual(output["month_upload_bytes"], 1300)

    def test_daily_only_state_migrates_without_losing_usage_on_update(self):
        # State written by the earlier daily-only build has no "month" or
        # rx_month/tx_month values. Installing the monthly build must preserve it.
        previous = {
            "version": 1,
            "date": "2026-10-10",
            "interfaces": {
                "wlp2s0": {
                    "name": "wlp2s0",
                    "type": "Wi-Fi",
                    "connection": "Home Wi-Fi",
                    "last_rx": 7000,
                    "last_tx": 1500,
                    "rx_today": 6000,
                    "tx_today": 1000,
                    "last_sample_ms": 12000,
                    "rx_bps": 0,
                    "tx_bps": 0,
                    "is_default": True,
                }
            },
        }
        state, output = METER.update_usage(previous, [sample(9000, 1800)], "2026-10-10", 14000)
        self.assertEqual(output["today_download_bytes"], 8000)
        self.assertEqual(output["today_upload_bytes"], 1300)
        self.assertEqual(output["month_download_bytes"], 8000)
        self.assertEqual(output["month_upload_bytes"], 1300)
        self.assertEqual(state["month"], "2026-10")

    def test_finds_saved_state_if_xdg_state_home_changes(self):
        old_state_file = METER.STATE_FILE
        old_default_file = METER.DEFAULT_STATE_FILE
        try:
            with tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                METER.STATE_FILE = root / "custom-xdg" / "a16een" / "data-meter.json"
                METER.DEFAULT_STATE_FILE = root / "home" / ".local/state/a16een/data-meter.json"
                METER.save_state({
                    "version": 2,
                    "date": "2026-10-10",
                    "month": "2026-10",
                    "interfaces": {"wlp2s0": {"rx_today": 123456, "last_sample_ms": 1000}},
                }, METER.DEFAULT_STATE_FILE)
                loaded = METER.load_state()
                self.assertEqual(loaded["interfaces"]["wlp2s0"]["rx_today"], 123456)
        finally:
            METER.STATE_FILE = old_state_file
            METER.DEFAULT_STATE_FILE = old_default_file

    def test_counter_reset_and_month_rollover(self):
        state, _ = METER.update_usage({}, [sample(10000, 800, "enp4s0")], "2026-10-10", 10000)
        state, _ = METER.update_usage(state, [sample(15000, 1200, "enp4s0")], "2026-10-10", 12000)
        _, reset = METER.update_usage(state, [sample(400, 100, "enp4s0")], "2026-10-10", 14000)
        self.assertEqual(reset["today_download_bytes"], 5400)
        self.assertEqual(reset["month_download_bytes"], 5400)

        _, next_month = METER.update_usage(
            state, [sample(16000, 1300, "enp4s0")], "2026-11-01", 20000
        )
        self.assertEqual(next_month["today_download_bytes"], 0)
        self.assertEqual(next_month["month_download_bytes"], 0)

    def test_day_rollover_keeps_month_and_starts_new_day(self):
        state, _ = METER.update_usage({}, [sample(10000, 800)], "2026-10-10", 10000)
        state, _ = METER.update_usage(state, [sample(15000, 1200)], "2026-10-10", 12000)
        _, output = METER.update_usage(state, [sample(16000, 1300)], "2026-10-11", 14000)
        self.assertEqual(output["today_download_bytes"], 1000)
        self.assertEqual(output["today_upload_bytes"], 100)
        self.assertEqual(output["month_download_bytes"], 6000)
        self.assertEqual(output["month_upload_bytes"], 500)

    def test_state_permissions(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "a16een" / "data-meter.json"
            METER.save_state({"date": "2026-10-10", "interfaces": {}}, path)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(path.parent.stat().st_mode & 0o777, 0o700)
            self.assertEqual(METER.load_state(path)["date"], "2026-10-10")


if __name__ == "__main__":
    unittest.main()
