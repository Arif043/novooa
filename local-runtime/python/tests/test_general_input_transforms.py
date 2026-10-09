import io
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy
from PIL import Image

from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.context import TransformationContext


def apply(value, *transformations):
    return default_transformation_registry().run(
        value,
        [{"type": kind, "parameters": parameters} for kind, parameters in transformations],
        TransformationContext(numpy, image_module=Image),
    ).value


def gradient_image(width, height):
    pixels = numpy.zeros((height, width, 3), dtype=numpy.uint8)
    pixels[..., 0] = numpy.arange(width, dtype=numpy.uint8)[numpy.newaxis, :]
    pixels[..., 1] = numpy.arange(height, dtype=numpy.uint8)[:, numpy.newaxis]
    return Image.fromarray(pixels, "RGB")


class ExifTransposeTest(unittest.TestCase):
    def test_rotates_a_photo_according_to_its_orientation(self):
        source = photo_with_orientation(width=40, height=20, orientation=6)

        result = apply(source, ("image.exifTranspose", {}))

        self.assertEqual(result.size, (20, 40))

    def test_keeps_images_without_orientation(self):
        source = gradient_image(40, 20)

        result = apply(source, ("image.exifTranspose", {}))

        self.assertEqual(result.size, (40, 20))

    def test_must_run_before_tensor_transformations(self):
        source = gradient_image(4, 4)
        with self.assertRaisesRegex(ValueError, "image.exifTranspose"):
            result = apply(source, ("tensor.scale", {"factor": 1}), ("image.exifTranspose", {}))


class ResizeShorterSideTest(unittest.TestCase):
    def test_scales_the_shorter_side_and_keeps_the_aspect_ratio(self):
        landscape = apply(gradient_image(400, 200), ("image.resizeShorterSide", {"size": 100}))
        portrait = apply(gradient_image(100, 300), ("image.resizeShorterSide", {"size": 50}))

        self.assertEqual(landscape.size, (200, 100))
        self.assertEqual(portrait.size, (50, 150))

    def test_rejects_a_missing_size(self):
        with self.assertRaisesRegex(ValueError, "positive ganze Zahlen"):
            apply(gradient_image(4, 4), ("image.resizeShorterSide", {}))


class CenterCropTest(unittest.TestCase):
    def test_cuts_out_the_center(self):
        source = gradient_image(10, 6)

        result = apply(source, ("image.centerCrop", {"width": 4, "height": 2}))

        pixels = numpy.asarray(result)
        self.assertEqual(result.size, (4, 2))
        self.assertEqual(int(pixels[0, 0, 0]), 3)
        self.assertEqual(int(pixels[0, 0, 1]), 2)

    def test_rejects_a_crop_larger_than_the_image(self):
        with self.assertRaisesRegex(ValueError, "größer als das Bild"):
            apply(gradient_image(4, 4), ("image.centerCrop", {"width": 5, "height": 2}))

    def test_combines_with_resize_shorter_side_to_the_usual_preprocessing(self):
        source = gradient_image(300, 200)

        result = apply(source,
            ("image.resizeShorterSide", {"size": 112}),
            ("image.centerCrop", {"width": 100, "height": 100}),
            ("tensor.scale", {"factor": 1 / 255}),
            ("tensor.layout", {"order": "channelsFirst"}),
        )

        self.assertEqual(result.shape, (3, 100, 100))
        self.assertLessEqual(float(result.max()), 1.0)


class InputTensorOperationsTest(unittest.TestCase):
    def test_scales_and_clips_image_pixels(self):
        source = Image.new("L", (2, 1), 255)

        result = apply(source, ("tensor.scale", {"factor": 2 / 255, "offset": -1}), ("tensor.clip", {"max": 0.5}))

        numpy.testing.assert_allclose(result.reshape(-1), [0.5, 0.5])

    def test_reshapes_and_transposes_the_tensor(self):
        source = gradient_image(4, 2)

        result = apply(source, ("tensor.transpose", {"axes": [2, 0, 1]}), ("tensor.reshape", {"shape": [3, -1]}))

        self.assertEqual(result.shape, (3, 8))


class NumberToTensorTest(unittest.TestCase):
    def test_turns_a_number_into_a_single_value_tensor(self):
        source = 2.5

        result = apply(source, ("number.toTensor", {}), ("tensor.scale", {"factor": 2}))

        numpy.testing.assert_allclose(result, [5.0])

    def test_accepts_a_list_of_numbers(self):
        source = [1, 2, 3]

        result = apply(source, ("number.toTensor", {}))

        numpy.testing.assert_allclose(result, [1, 2, 3])

    def test_rejects_non_numeric_values(self):
        for value in ["7", True, [1, "x"], []]:
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "number.toTensor"):
                apply(value, ("number.toTensor", {}))


def photo_with_orientation(width, height, orientation):
    exif = Image.Exif()
    exif[0x0112] = orientation
    buffer = io.BytesIO()
    gradient_image(width, height).save(buffer, format="JPEG", exif=exif)
    buffer.seek(0)
    return Image.open(buffer)


if __name__ == "__main__":
    unittest.main()
