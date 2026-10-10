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

class DataMeterTests(unittest.TestCase):
    def test_first_sample_is_baseline(self):
        state, output = METER.update_usage({}, [{"name":"wlp2s0","type":"Wi-Fi","connection":"Home Wi-Fi","is_default":True,"rx":1000,"tx":500}], "2026-10-10", 10000)
        self.assertEqual(output["today_download_bytes"], 0)
        self.assertEqual(output["connection_name"], "Home Wi-Fi")
        self.assertEqual(state["date"], "2026-10-10")

    def test_daily_usage_and_speed(self):
        state, _ = METER.update_usage({}, [{"name":"wlp2s0","type":"Wi-Fi","connection":"Home Wi-Fi","is_default":True,"rx":1000,"tx":500}], "2026-10-10", 10000)
        state, output = METER.update_usage(state, [{"name":"wlp2s0","type":"Wi-Fi","connection":"Home Wi-Fi","is_default":True,"rx":7000,"tx":1500}], "2026-10-10", 12000)
        self.assertEqual(output["today_download_bytes"], 6000)
        self.assertEqual(output["today_upload_bytes"], 1000)
        self.assertEqual(output["down_bps"], 3000)
        self.assertEqual(output["up_bps"], 500)

    def test_counter_reset_and_day_rollover(self):
        state, _ = METER.update_usage({}, [{"name":"enp4s0","is_default":True,"rx":10000,"tx":800}], "2026-10-10", 10000)
        state, _ = METER.update_usage(state, [{"name":"enp4s0","is_default":True,"rx":15000,"tx":1200}], "2026-10-10", 12000)
        _, output = METER.update_usage(state, [{"name":"enp4s0","is_default":True,"rx":400,"tx":100}], "2026-10-10", 14000)
        self.assertEqual(output["today_download_bytes"], 5400)
        _, next_day = METER.update_usage(state, [{"name":"enp4s0","is_default":True,"rx":16000,"tx":1300}], "2026-10-11", 20000)
        self.assertEqual(next_day["today_download_bytes"], 0)

    def test_state_permissions(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "a16een" / "data-meter.json"
            METER.save_state({"date":"2026-10-10","interfaces":{}}, path)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(path.parent.stat().st_mode & 0o777, 0o700)
            self.assertEqual(METER.load_state(path)["date"], "2026-10-10")

if __name__ == "__main__":
    unittest.main()
