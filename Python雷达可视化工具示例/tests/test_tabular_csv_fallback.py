"""验证普通矩形 CSV 能进入备用解析路径。"""

import importlib.util
import os
from pathlib import Path
import sys
import tempfile
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


class TabularCsvFallbackTest(unittest.TestCase):
    def test_frame_number_can_precede_object_id(self):
        radar_viewer = load_radar_viewer()
        with tempfile.TemporaryDirectory() as temp_dir:
            fixture = Path(temp_dir) / "targets.csv"
            fixture.write_text(
                "FrameNb,ObjId,range,speed,angle,RCS,snr,X,Y\n"
                "12,7,2.5,0.1,-5,3,20,2.49,-0.22\n",
                encoding="utf-8",
            )

            parser = radar_viewer.RadarParser(fixture)
            frame = parser.get_frame(12)

        self.assertEqual(list(parser.frame_index), [12])
        self.assertEqual(frame["ObjId"].tolist(), [7])
        self.assertEqual(frame["range"].tolist(), [2.5])


if __name__ == "__main__":
    unittest.main()
