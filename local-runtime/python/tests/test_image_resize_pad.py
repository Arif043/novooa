import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy

from novooa_ml.input_transforms.image.resize_pad import ImageResizePadStrategy
from novooa_ml.transformations.context import TransformationContext


class ImageResizePadStrategyTest(unittest.TestCase):
    def test_preserves_aspect_ratio_and_pads_at_the_top_left(self):
        source = ImageRecorder((100, 20))
        context = ImageContext(source)

        context.image = ImageResizePadStrategy().transform(context.image, {"width": 200, "height": 100}, context)

        self.assertEqual(source.resize_size, (200, 40))
        self.assertEqual(context.image.size, (200, 100))
        self.assertEqual(context.image.paste_offset, (0, 0))

    def test_can_center_the_resized_image(self):
        source = ImageRecorder((100, 20))
        context = ImageContext(source)

        context.image = ImageResizePadStrategy().transform(
            context.image, {"width": 200, "height": 100, "alignment": "center"}, context
        )

        self.assertEqual(context.image.paste_offset, (0, 30))

    def test_rejects_an_unknown_alignment(self):
        with self.assertRaisesRegex(ValueError, "topLeft oder center"):
            ImageResizePadStrategy().transform(
                ImageRecorder((10, 10)),
                {"width": 20, "height": 20, "alignment": "bottomRight"},
                TransformationContext(numpy, image_module=ImageModule),
            )


class ImageContext(TransformationContext):
    """Kontext mit Fake-Bildmodul; hält das zuletzt erzeugte Bild für die Prüfung."""

    def __init__(self, image):
        super().__init__(numpy, image_module=ImageModule)
        self.image = image


class ImageRecorder:
    mode = "RGB"

    def __init__(self, size):
        self.size = size
        self.resize_size = None

    def resize(self, size, _):
        self.resize_size = size
        return ResizedImage(size)


class ResizedImage:
    def __init__(self, size):
        self.size = size


class Canvas:
    def __init__(self, size):
        self.size = size
        self.paste_offset = None

    def paste(self, _, offset):
        self.paste_offset = offset


class ImageModule:
    class Resampling:
        LANCZOS = "lanczos"

    @staticmethod
    def new(_, size, __):
        return Canvas(size)


if __name__ == "__main__":
    unittest.main()
