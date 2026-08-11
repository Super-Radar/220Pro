"""验证缺少 SciPy 时跟踪功能能够安全降级。"""

import importlib.util
import os
from pathlib import Path
import sys
import tkinter as tk
import types
import unittest

import pandas as pd


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


class TrackingWithoutScipyTest(unittest.TestCase):
    def test_tracking_falls_back_to_object_ids(self):
        radar_viewer = load_radar_viewer()
        tk._default_root = tk.Tcl()
        tracker = radar_viewer.KalmanTracker()
        tracker.enable_tracking.set(True)
        radar_viewer.linear_sum_assignment = None
        frame = pd.DataFrame({"ObjId": [7], "X": [1.0], "Y": [2.0]})

        first = tracker.track(frame.copy())
        second = tracker.track(frame.copy())

        self.assertEqual(first["track_id"].tolist(), [7])
        self.assertEqual(second["track_id"].tolist(), [7])
        self.assertEqual(tracker.tracked_targets, {})


if __name__ == "__main__":
    unittest.main()
