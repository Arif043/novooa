import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy
from PIL import Image

from ml_test_support import run


def checkerboard():
    pixels = numpy.zeros((4, 6, 3), dtype=numpy.uint8)
    pixels[:2, :3] = (255, 0, 0)
    pixels[2:, 3:] = (0, 0, 255)
    return Image.fromarray(pixels, "RGB")


class DecodeTest(unittest.TestCase):
    def test_converts_between_color_spaces(self):
        for color_space, mode in [("grayscale", "L"), ("rgba", "RGBA"), ("rgb", "RGB")]:
            with self.subTest(color_space=color_space):
                self.assertEqual(run(Image.new("RGB", (2, 2)), ("image.decode", {"colorSpace": color_space})).mode, mode)

    def test_rejects_an_unknown_color_space(self):
        with self.assertRaisesRegex(ValueError, "rgb, rgba oder grayscale"):
            run(Image.new("RGB", (2, 2)), ("image.decode", {"colorSpace": "cmyk"}))


class ResizeTest(unittest.TestCase):
    def test_scales_to_the_exact_size_and_optional_color_space(self):
        image = run(checkerboard(), ("image.resize", {"width": 12, "height": 2, "colorSpace": "grayscale"}))

        self.assertEqual((image.size, image.mode), ((12, 2), "L"))

    def test_rejects_missing_dimensions(self):
        with self.assertRaisesRegex(ValueError, "positive ganze Zahlen"):
            run(checkerboard(), ("image.resize", {"width": 0, "height": 2}))


class CropTest(unittest.TestCase):
    def test_cuts_out_the_declared_pixels(self):
        image = run(checkerboard(), ("image.crop", {"left": 3, "top": 2, "width": 3, "height": 2}))

        self.assertEqual(image.size, (3, 2))
        self.assertEqual(set(image.getdata()), {(0, 0, 255)})

    def test_rejects_negative_positions_and_crops_outside_the_image(self):
        with self.assertRaisesRegex(ValueError, "nichtnegative Ganzzahl für left"):
            run(checkerboard(), ("image.crop", {"left": -1, "top": 0, "width": 1, "height": 1}))
        with self.assertRaisesRegex(ValueError, "außerhalb des Bildes"):
            run(checkerboard(), ("image.crop", {"left": 4, "top": 0, "width": 3, "height": 1}))


class PerspectiveCropTest(unittest.TestCase):
    def test_an_axis_aligned_quadrilateral_behaves_like_a_crop(self):
        image = run(checkerboard(), ("image.perspectiveCrop", {"points": [0, 0, 0, 2, 3, 2, 3, 0], "width": 3, "height": 2}))

        self.assertEqual(image.size, (3, 2))
        self.assertEqual(image.getpixel((1, 1)), (255, 0, 0))

    def test_requires_four_numeric_points(self):
        with self.assertRaisesRegex(ValueError, "vier Punkte"):
            run(checkerboard(), ("image.perspectiveCrop", {"points": [0, 0, 1, 1], "width": 1, "height": 1}))
        with self.assertRaisesRegex(ValueError, "numerische Punkte"):
            run(checkerboard(), ("image.perspectiveCrop", {"points": ["a"] * 8, "width": 1, "height": 1}))


class PaddingTest(unittest.TestCase):
    def test_pad_to_multiple_fills_right_and_bottom_with_the_background(self):
        image = run(Image.new("L", (5, 3), 9), ("image.padToMultiple", {"multiple": 4, "background": 200}))

        self.assertEqual(image.size, (8, 4))
        self.assertEqual((image.getpixel((0, 0)), image.getpixel((7, 3))), (9, 200))

    def test_resize_pad_keeps_the_aspect_ratio_and_centers(self):
        image = run(Image.new("L", (10, 5), 255), ("image.resizePad", {"width": 20, "height": 20, "alignment": "center"}))

        self.assertEqual(image.size, (20, 20))
        self.assertEqual((image.getpixel((10, 0)), image.getpixel((10, 10))), (0, 255))

    def test_rejects_an_invalid_background(self):
        with self.assertRaisesRegex(ValueError, "Hintergrundfarbe"):
            run(Image.new("L", (5, 3)), ("image.padToMultiple", {"multiple": 4, "background": 300}))


class StepsAfterTensorTest(unittest.TestCase):
    def test_every_image_step_refuses_a_tensor(self):
        steps = ["image.decode", "image.resize", "image.resizePad", "image.resizeHeightPad", "image.resizeShorterSide",
                 "image.padToMultiple", "image.crop", "image.centerCrop", "image.perspectiveCrop", "image.exifTranspose"]
        for step in steps:
            with self.subTest(step=step), self.assertRaisesRegex(ValueError, f"{step} muss vor Tensortransformationen stehen"):
                run(numpy.zeros((2, 2, 3)), (step, {}))


if __name__ == "__main__":
    unittest.main()
