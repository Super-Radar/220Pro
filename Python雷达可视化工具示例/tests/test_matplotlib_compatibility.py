"""验证 Python 可视化工具与当前 Matplotlib API 的兼容性。"""

import importlib.util
import os
from pathlib import Path
import sys
import tkinter as tk
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


class MatplotlibCompatibilityTest(unittest.TestCase):
    def test_cluster_colormap_can_be_created(self):
        """Matplotlib 3.11 中仍应能初始化聚类器。"""
        radar_viewer = load_radar_viewer()
        tk._default_root = tk.Tcl()

        cluster = radar_viewer.RadarCluster()

        self.assertEqual(cluster.cluster_colors.N, 20)


if __name__ == "__main__":
    unittest.main()
