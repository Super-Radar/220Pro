"""Python 雷达可视化工具测试的无图形界面加载辅助函数。"""

from contextlib import contextmanager
import importlib.util
import os
from pathlib import Path
import sys
import tkinter as tk
import types


os.environ.setdefault("MPLBACKEND", "Agg")
EXAMPLE_DIR = Path(__file__).resolve().parents[1]
_MISSING = object()


def load_radar_viewer(module_name, *, without_scipy=False):
    """隔离加载示例脚本，并恢复临时替换的后端与可选依赖。"""
    fake_backend = types.ModuleType("matplotlib.backends.backend_tkagg")
    fake_backend.FigureCanvasTkAgg = object
    replacements = {"matplotlib.backends.backend_tkagg": fake_backend}
    if without_scipy:
        replacements["scipy.optimize"] = types.ModuleType("scipy.optimize")

    originals = {name: sys.modules.get(name, _MISSING) for name in replacements}
    sys.modules.update(replacements)
    try:
        script_path = EXAMPLE_DIR / "radarViewer.py"
        spec = importlib.util.spec_from_file_location(module_name, script_path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        for name, original in originals.items():
            if original is _MISSING:
                sys.modules.pop(name, None)
            else:
                sys.modules[name] = original


@contextmanager
def tkinter_root():
    """为 Tk 变量提供临时 Tcl 根，并在测试后恢复全局状态。"""
    original_root = tk._default_root
    tk._default_root = tk.Tcl()
    try:
        yield
    finally:
        tk._default_root = original_root


class Value:
    """提供测试所需的最小 Tk 变量接口。"""

    def __init__(self, value):
        self.value = value

    def get(self):
        return self.value
