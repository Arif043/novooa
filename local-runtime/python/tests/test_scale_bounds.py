import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformations.vision.scale_bounds import ScaleBoundsStrategy


class ScaleBoundsStrategyTest(unittest.TestCase):
    def test_scales_regions_without_losing_their_metadata(self):
        values = ScaleBoundsStrategy().transform(
            [{"bounds": {"left": 2, "top": 3, "width": 4, "height": 5}, "pixelCount": 20}],
            {"scaleX": 4, "scaleY": 4, "offsetX": 1, "offsetY": 2},
            None,
        )

        self.assertEqual(values, [{
            "bounds": {"left": 9, "top": 14, "width": 16, "height": 20},
            "pixelCount": 20,
        }])

    def test_rejects_non_region_values(self):
        with self.assertRaisesRegex(ValueError, "Liste von Regionen"):
            ScaleBoundsStrategy().transform({}, {"scaleX": 4, "scaleY": 4}, None)

    def test_rejects_non_positive_scale(self):
        with self.assertRaisesRegex(ValueError, "positiven Wert"):
            ScaleBoundsStrategy().transform([], {"scaleX": 0, "scaleY": 4}, None)


if __name__ == "__main__":
    unittest.main()
