"""验证播放暂停不会遗留并行计时器。"""

import importlib.util
import os
from pathlib import Path
import sys
import types
import unittest


os.environ.setdefault("MPLBACKEND", "Agg")


def load_radar_viewer():
    """在无图形窗口的测试环境中加载示例脚本。"""
    fake_backend = types.ModuleType("matplotlib.backends.backend_tkagg")
    fake_backend.FigureCanvasTkAgg = object
    sys.modules["matplotlib.backends.backend_tkagg"] = fake_backend

    script_path = Path(__file__).resolve().parents[1] / "radarViewer.py"
    spec = importlib.util.spec_from_file_location("radar_viewer", script_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class PlaybackTimerTest(unittest.TestCase):
    def test_pause_cancels_pending_callback_before_resume(self):
        radar_viewer = load_radar_viewer()

        class FakePlayer:
            toggle = radar_viewer.RadarPlayer.toggle
            loop = radar_viewer.RadarPlayer.loop

            def __init__(self):
                self.fns = [0, 1, 2]
                self.current = 0
                self.playing = True
                self.timer = "pending-timer"
                self.cancelled = []
                self.scheduled = []
                self.speed_var = types.SimpleNamespace(get=lambda: 100)

            def update_frame(self):
                pass

            def after(self, delay, callback):
                token = f"timer-{len(self.scheduled) + 1}"
                self.scheduled.append((token, delay, callback))
                return token

            def after_cancel(self, token):
                self.cancelled.append(token)

        player = FakePlayer()
        player.toggle()
        player.toggle()

        self.assertEqual(player.cancelled, ["pending-timer"])
        self.assertEqual(len(player.scheduled), 1)
        self.assertEqual(player.timer, "timer-1")
        self.assertEqual(player.current, 1)


if __name__ == "__main__":
    unittest.main()
