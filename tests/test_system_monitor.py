from __future__ import annotations
import importlib.machinery
import importlib.util
import unittest
from pathlib import Path
SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "a16een-system-monitor"
LOADER = importlib.machinery.SourceFileLoader("a16een_system_monitor", str(SCRIPT))
SPEC = importlib.util.spec_from_loader("a16een_system_monitor", LOADER)
MONITOR = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(MONITOR)

class SystemMonitorTests(unittest.TestCase):
    def test_cpu_busy_ratio(self) -> None:
        self.assertAlmostEqual(MONITOR.cpu_percent((1000, 700), (1100, 730)), 70.0)
    def test_idle_cpu(self) -> None:
        self.assertEqual(MONITOR.cpu_percent((1000, 700), (1100, 800)), 0.0)
    def test_cpu_values_are_clamped(self) -> None:
        self.assertEqual(MONITOR.cpu_percent((10, 9), (10, 9)), 0.0)
    def test_memory_used_uses_available_memory(self) -> None:
        used, total = MONITOR.parse_meminfo("MemTotal: 16384 kB\nMemAvailable: 4096 kB\nMemFree: 1024 kB\n")
        self.assertEqual(total, 16384 * 1024)
        self.assertEqual(used, 12288 * 1024)
    def test_memory_fallback_without_memavailable(self) -> None:
        used, total = MONITOR.parse_meminfo("MemTotal: 1000 kB\nMemFree: 200 kB\nBuffers: 100 kB\nCached: 300 kB\n")
        self.assertEqual(total, 1000 * 1024)
        self.assertEqual(used, 400 * 1024)
    def test_invalid_memory_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            MONITOR.parse_meminfo("MemFree: 123 kB\n")

if __name__ == "__main__":
    unittest.main()
