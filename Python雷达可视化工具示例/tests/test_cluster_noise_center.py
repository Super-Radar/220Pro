import sys
import types
import unittest
from pathlib import Path

import numpy as np
import pandas as pd


EXAMPLE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(EXAMPLE_DIR))
fake_backend = types.ModuleType('matplotlib.backends.backend_tkagg')
fake_backend.FigureCanvasTkAgg = object
sys.modules['matplotlib.backends.backend_tkagg'] = fake_backend

import radarViewer  # noqa: E402


class _Value:
    """为聚类单测提供不依赖图形界面的 Tk 变量替身。"""

    def __init__(self, value):
        self.value = value

    def get(self):
        return self.value


class RadarClusterNoiseCenterTest(unittest.TestCase):
    def test_noise_center_falls_back_to_its_own_scalar_coordinates(self):
        cluster = radarViewer.RadarCluster.__new__(radarViewer.RadarCluster)
        cluster.enable_clustering = _Value(True)
        cluster.eps = _Value(0.5)
        cluster.min_samples = _Value(2)

        points = pd.DataFrame({
            'X': [0.0, 0.2, 10.0],
            'Y': [0.0, 0.2, 20.0],
        })

        result = cluster.cluster(points)

        grouped = result[result['cluster_id'] == 0]
        for center in grouped['cluster_center_x']:
            self.assertAlmostEqual(center, 0.1)
        for center in grouped['cluster_center_y']:
            self.assertAlmostEqual(center, 0.1)
        self.assertEqual(grouped['cluster_size'].tolist(), [2, 2])

        noise = result[result['cluster_id'] == -1].iloc[0]
        self.assertEqual(noise['cluster_center_x'], 10.0)
        self.assertEqual(noise['cluster_center_y'], 20.0)
        self.assertEqual(noise['cluster_size'], 1)
        self.assertTrue(all(np.isscalar(value) for value in result['cluster_center_x']))
        self.assertTrue(all(np.isscalar(value) for value in result['cluster_center_y']))


if __name__ == '__main__':
    unittest.main()
