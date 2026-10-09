import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformations.registry import TransformationRegistry
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.input_transforms.default_registry import default_transformation_registry
from novooa_ml.transformations.context import TransformationContext


class TransformRegistryTest(unittest.TestCase):
    def test_applies_independent_strategies_in_contract_order(self):
        first = RecordingStrategy("first")
        second = RecordingStrategy("second")
        result = TransformationRegistry([first, second]).run(
            [],
            [
                {"type": "first", "parameters": {}, "result": "nachErstem"},
                {"type": "second", "parameters": {}},
            ],
            None,
        )

        self.assertEqual(result.value, ["first", "second"])
        self.assertEqual(result.results, {"nachErstem": ["first"]})

    def test_rejects_an_unregistered_transformation(self):
        registry = TransformationRegistry([])

        with self.assertRaisesRegex(ValueError, "Nicht unterstützte Transformation"):
            registry.run(None, [{"type": "unknown", "parameters": {}}], None)

    def test_discovers_registered_strategy_modules(self):
        self.assertIn(
            "text.piperPhonemes",
            default_transformation_registry().supported_types,
        )
        self.assertIn(
            "text.kokoroTokens",
            default_transformation_registry().supported_types,
        )


class RecordingStrategy(TransformationStrategy):
    def __init__(self, name):
        self._name = name

    @property
    def transformation_type(self):
        return self._name

    def transform(self, value, parameters, context):
        return [*value, self._name]


class ImageCropStrategyTest(unittest.TestCase):
    def test_crops_a_declared_rectangle(self):
        from novooa_ml.input_transforms.image.crop import ImageCropStrategy

        image = ImageRecorder((20, 10))
        ImageCropStrategy().transform(
            image, {"left": 2, "top": 3, "width": 8, "height": 4}, image_context()
        )

        self.assertEqual(image.crop_box, (2, 3, 10, 7))

    def test_rejects_a_crop_outside_the_image(self):
        from novooa_ml.input_transforms.image.crop import ImageCropStrategy

        with self.assertRaisesRegex(ValueError, "außerhalb"):
            ImageCropStrategy().transform(
                ImageRecorder((10, 10)),
                {"left": 2, "top": 3, "width": 9, "height": 4},
                image_context(),
            )


class ImagePerspectiveCropStrategyTest(unittest.TestCase):
    def test_transforms_a_declared_quadrilateral(self):
        from novooa_ml.input_transforms.image.perspective_crop import ImagePerspectiveCropStrategy

        image = ImageRecorder((20, 10))
        ImagePerspectiveCropStrategy().transform(
            image,
            {"points": [0, 0, 10, 0, 10, 8, 0, 8], "width": 10, "height": 8},
            image_context(),
        )

        self.assertEqual(image.transformation[0], (10, 8))
        self.assertEqual(image.transformation[2], (0, 0, 10, 0, 10, 8, 0, 8))


def image_context():
    import numpy

    return TransformationContext(numpy, image_module=ImageModule)


class ImageRecorder:
    mode = "RGB"

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


if __name__ == "__main__":
    unittest.main()
