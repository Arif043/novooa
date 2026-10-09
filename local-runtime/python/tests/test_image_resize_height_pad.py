import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.context import TransformationContext


class ImageResizeHeightPadStrategyTest(unittest.TestCase):
    def setUp(self):
        import numpy
        from PIL import Image

        self.numpy = numpy
        self.image = Image

    def test_scales_a_wide_region_to_the_target_height(self):
        image = self.resized((260, 14), 255, {"width": 320, "height": 48})

        self.assertEqual(image.size, (320, 48))
        self.assertEqual(image.getpixel((319, 47)), 255)

    def test_pads_a_narrow_region_after_scaling(self):
        image = self.resized((20, 14), 255, {"width": 320, "height": 48, "background": 0})

        self.assertEqual(image.size, (320, 48))
        self.assertEqual(image.getpixel((319, 47)), 0)

    def test_keeps_the_scaled_width_dynamic_when_no_width_is_declared(self):
        image = self.resized((260, 14), 255, {"height": 48, "widthMultiple": 8})

        self.assertEqual(image.size, (896, 48))

    def resized(self, size, fill, parameters):
        return default_transformation_registry().run(
            self.image.new("L", size, fill),
            [{"type": "image.resizeHeightPad", "parameters": parameters}],
            TransformationContext(self.numpy, image_module=self.image),
        ).value


if __name__ == "__main__":
    unittest.main()
