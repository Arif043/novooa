import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.input_transforms.context import ImageTransformContext
from novooa_ml.input_transforms.default_registry import default_transformation_registry


class ImageResizeHeightPadStrategyTest(unittest.TestCase):
    def setUp(self):
        import numpy
        from PIL import Image

        self.numpy = numpy
        self.image = Image

    def test_scales_a_wide_region_to_the_target_height(self):
        context = self.context((260, 14), 255)
        default_transformation_registry().apply(
            context,
            [{"type": "image.resizeHeightPad", "parameters": {"width": 320, "height": 48}}],
        )
        self.assertEqual(context.image.size, (320, 48))
        self.assertEqual(context.image.getpixel((319, 47)), 255)

    def test_pads_a_narrow_region_after_scaling(self):
        context = self.context((20, 14), 255)
        default_transformation_registry().apply(
            context,
            [{
                "type": "image.resizeHeightPad",
                "parameters": {"width": 320, "height": 48, "background": 0},
            }],
        )
        self.assertEqual(context.image.size, (320, 48))
        self.assertEqual(context.image.getpixel((319, 47)), 0)


    def test_keeps_the_scaled_width_dynamic_when_no_width_is_declared(self):
        context = self.context((260, 14), 255)
        default_transformation_registry().apply(
            context,
            [{
                "type": "image.resizeHeightPad",
                "parameters": {"height": 48, "widthMultiple": 8},
            }],
        )

        self.assertEqual(context.image.size, (896, 48))

    def context(self, size, fill):
        return ImageTransformContext(
            self.image.new("L", size, fill), self.numpy, self.image
        )


if __name__ == "__main__":
    unittest.main()
