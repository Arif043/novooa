import io
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy
from PIL import Image

from novooa_ml.input_transforms.context import ImageTransformContext, NumberTransformContext
from novooa_ml.input_transforms.default_registry import default_transformation_registry


def apply(context, *transformations):
    return default_transformation_registry().apply(
        context, [{"type": kind, "parameters": parameters} for kind, parameters in transformations]
    )


def image_context(image):
    return ImageTransformContext(image, numpy, Image)


def gradient_image(width, height):
    pixels = numpy.zeros((height, width, 3), dtype=numpy.uint8)
    pixels[..., 0] = numpy.arange(width, dtype=numpy.uint8)[numpy.newaxis, :]
    pixels[..., 1] = numpy.arange(height, dtype=numpy.uint8)[:, numpy.newaxis]
    return Image.fromarray(pixels, "RGB")


class ExifTransposeTest(unittest.TestCase):
    def test_rotates_a_photo_according_to_its_orientation(self):
        context = image_context(photo_with_orientation(width=40, height=20, orientation=6))

        apply(context, ("image.exifTranspose", {}))

        self.assertEqual(context.image.size, (20, 40))

    def test_keeps_images_without_orientation(self):
        context = image_context(gradient_image(40, 20))

        apply(context, ("image.exifTranspose", {}))

        self.assertEqual(context.image.size, (40, 20))

    def test_must_run_before_tensor_transformations(self):
        context = image_context(gradient_image(4, 4))
        with self.assertRaisesRegex(ValueError, "image.exifTranspose"):
            apply(context, ("tensor.scale", {"factor": 1}), ("image.exifTranspose", {}))


class ResizeShorterSideTest(unittest.TestCase):
    def test_scales_the_shorter_side_and_keeps_the_aspect_ratio(self):
        landscape = image_context(gradient_image(400, 200))
        portrait = image_context(gradient_image(100, 300))

        apply(landscape, ("image.resizeShorterSide", {"size": 100}))
        apply(portrait, ("image.resizeShorterSide", {"size": 50}))

        self.assertEqual(landscape.image.size, (200, 100))
        self.assertEqual(portrait.image.size, (50, 150))

    def test_rejects_a_missing_size(self):
        with self.assertRaisesRegex(ValueError, "positive ganze Zahlen"):
            apply(image_context(gradient_image(4, 4)), ("image.resizeShorterSide", {}))


class CenterCropTest(unittest.TestCase):
    def test_cuts_out_the_center(self):
        context = image_context(gradient_image(10, 6))

        apply(context, ("image.centerCrop", {"width": 4, "height": 2}))

        pixels = numpy.asarray(context.image)
        self.assertEqual(context.image.size, (4, 2))
        self.assertEqual(int(pixels[0, 0, 0]), 3)
        self.assertEqual(int(pixels[0, 0, 1]), 2)

    def test_rejects_a_crop_larger_than_the_image(self):
        with self.assertRaisesRegex(ValueError, "größer als das Bild"):
            apply(image_context(gradient_image(4, 4)), ("image.centerCrop", {"width": 5, "height": 2}))

    def test_combines_with_resize_shorter_side_to_the_usual_preprocessing(self):
        context = image_context(gradient_image(300, 200))

        apply(
            context,
            ("image.resizeShorterSide", {"size": 112}),
            ("image.centerCrop", {"width": 100, "height": 100}),
            ("tensor.scale", {"factor": 1 / 255}),
            ("tensor.layout", {"order": "channelsFirst"}),
        )

        self.assertEqual(context.tensor.shape, (3, 100, 100))
        self.assertLessEqual(float(context.tensor.max()), 1.0)


class InputTensorOperationsTest(unittest.TestCase):
    def test_scales_and_clips_image_pixels(self):
        context = image_context(Image.new("L", (2, 1), 255))

        apply(context, ("tensor.scale", {"factor": 2 / 255, "offset": -1}), ("tensor.clip", {"max": 0.5}))

        numpy.testing.assert_allclose(context.tensor.reshape(-1), [0.5, 0.5])

    def test_reshapes_and_transposes_the_tensor(self):
        context = image_context(gradient_image(4, 2))

        apply(context, ("tensor.transpose", {"axes": [2, 0, 1]}), ("tensor.reshape", {"shape": [3, -1]}))

        self.assertEqual(context.tensor.shape, (3, 8))


class NumberToTensorTest(unittest.TestCase):
    def test_turns_a_number_into_a_single_value_tensor(self):
        context = NumberTransformContext(2.5, numpy)

        apply(context, ("number.toTensor", {}), ("tensor.scale", {"factor": 2}))

        numpy.testing.assert_allclose(context.tensor, [5.0])

    def test_accepts_a_list_of_numbers(self):
        context = NumberTransformContext([1, 2, 3], numpy)

        apply(context, ("number.toTensor", {}))

        numpy.testing.assert_allclose(context.tensor, [1, 2, 3])

    def test_rejects_non_numeric_values(self):
        for value in ["7", True, [1, "x"], []]:
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "number.toTensor"):
                apply(NumberTransformContext(value, numpy), ("number.toTensor", {}))


def photo_with_orientation(width, height, orientation):
    exif = Image.Exif()
    exif[0x0112] = orientation
    buffer = io.BytesIO()
    gradient_image(width, height).save(buffer, format="JPEG", exif=exif)
    buffer.seek(0)
    return Image.open(buffer)


if __name__ == "__main__":
    unittest.main()
