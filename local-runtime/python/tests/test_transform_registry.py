import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.input_transforms.registry import TransformationRegistry
from novooa_ml.input_transforms.strategy import InputTransformStrategy
from novooa_ml.input_transforms.default_registry import default_transformation_registry


class TransformRegistryTest(unittest.TestCase):
    def test_applies_independent_strategies_in_contract_order(self):
        first = RecordingStrategy("first")
        second = RecordingStrategy("second")
        context = {"calls": []}

        TransformationRegistry([first, second]).apply(
            context,
            [
                {"type": "first", "parameters": {}},
                {"type": "second", "parameters": {}},
            ],
        )

        self.assertEqual(context["calls"], ["first", "second"])

    def test_rejects_an_unregistered_transformation(self):
        registry = TransformationRegistry([])

        with self.assertRaisesRegex(ValueError, "Nicht unterstützte Transformation"):
            registry.apply({}, [{"type": "unknown", "parameters": {}}])

    def test_discovers_registered_strategy_modules(self):
        self.assertIn(
            "text.piperPhonemes",
            default_transformation_registry().supported_types,
        )
        self.assertIn(
            "text.kokoroTokens",
            default_transformation_registry().supported_types,
        )


class RecordingStrategy(InputTransformStrategy):
    def __init__(self, name):
        self._name = name

    @property
    def transformation_type(self):
        return self._name

    def transform(self, context, parameters):
        context["calls"].append(self._name)


if __name__ == "__main__":
    unittest.main()


class ImageCropStrategyTest(unittest.TestCase):
    def test_crops_a_declared_rectangle(self):
        from novooa_ml.input_transforms.image_crop_strategy import ImageCropStrategy

        image = ImageRecorder((20, 10))
        context = ImageContext(image)

        ImageCropStrategy().transform(
            context, {"left": 2, "top": 3, "width": 8, "height": 4}
        )

        self.assertEqual(image.crop_box, (2, 3, 10, 7))

    def test_rejects_a_crop_outside_the_image(self):
        from novooa_ml.input_transforms.image_crop_strategy import ImageCropStrategy

        with self.assertRaisesRegex(ValueError, "außerhalb"):
            ImageCropStrategy().transform(
                ImageContext(ImageRecorder((10, 10))),
                {"left": 2, "top": 3, "width": 9, "height": 4},
            )


class ImagePerspectiveCropStrategyTest(unittest.TestCase):
    def test_transforms_a_declared_quadrilateral(self):
        from novooa_ml.input_transforms.image_perspective_crop_strategy import (
            ImagePerspectiveCropStrategy,
        )

        image = ImageRecorder((20, 10))
        context = ImageContext(image)

        ImagePerspectiveCropStrategy().transform(
            context,
            {"points": [0, 0, 10, 0, 10, 8, 0, 8], "width": 10, "height": 8},
        )

        self.assertEqual(image.transformation[0], (10, 8))
        self.assertEqual(image.transformation[2], (0, 0, 10, 0, 10, 8, 0, 8))


class ImageContext:
    def __init__(self, image):
        self.image = image
        self.image_module = ImageModule

    def require_image(self, _):
        return None


class ImageRecorder:
    def __init__(self, size):
        self.size = size
        self.crop_box = None
        self.transformation = None

    def crop(self, box):
        self.crop_box = box
        return self

    def transform(self, *args, **kwargs):
        self.transformation = args + (kwargs["resample"],)
        return self


class ImageModule:
    class Transform:
        QUAD = "quad"

    class Resampling:
        BICUBIC = "bicubic"
