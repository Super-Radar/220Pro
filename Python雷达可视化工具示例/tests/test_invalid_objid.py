import importlib.util
import sys
import tempfile
import types
import unittest
from pathlib import Path


def load_radar_viewer():
    """在无图形界面的测试环境中加载解析器模块。"""
    module_path = Path(__file__).resolve().parents[1] / "radarViewer.py"
    fake_backend = types.ModuleType("matplotlib.backends.backend_tkagg")
    fake_backend.FigureCanvasTkAgg = object

    module_name = "radar_viewer_invalid_objid_test"
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    module = importlib.util.module_from_spec(spec)
    original_backend = sys.modules.get("matplotlib.backends.backend_tkagg")
    sys.modules["matplotlib.backends.backend_tkagg"] = fake_backend
    try:
        spec.loader.exec_module(module)
    finally:
        if original_backend is None:
            sys.modules.pop("matplotlib.backends.backend_tkagg", None)
        else:
            sys.modules["matplotlib.backends.backend_tkagg"] = original_backend
    return module


radar_viewer = load_radar_viewer()


class InvalidObjIdFallbackTest(unittest.TestCase):
    def test_non_numeric_objid_is_dropped_before_other_numeric_defaults(self):
        # 无 START/END 元数据的普通 CSV 会走 pandas fallback 路径。
        csv_text = "\n".join([
            "ObjId,range,speed,angle,RCS,snr,X,Y,FrameNb,Timestamp",
            "not-an-id,4.0,1.0,0,2,10,4,0,12,2026-08-11 10:00:00",
            ",5.0,2.0,0,3,11,5,0,12,2026-08-11 10:00:00",
            "7,6.0,invalid-speed,0,4,12,6,0,12,2026-08-11 10:00:00",
        ])

        with tempfile.TemporaryDirectory() as temp_dir:
            fixture = Path(temp_dir) / "targets.csv"
            fixture.write_text(csv_text, encoding="utf-8")
            frame = radar_viewer.RadarParser(fixture).get_frame(12)

        self.assertEqual(frame["ObjId"].tolist(), [7.0])
        # 其他非关键数值字段仍按原有行为填充为 0。
        self.assertEqual(frame["speed"].tolist(), [0.0])


if __name__ == "__main__":
    unittest.main()
