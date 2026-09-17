import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.input_transforms.image_resize_pad_strategy import ImageResizePadStrategy


class ImageResizePadStrategyTest(unittest.TestCase):
    def test_preserves_aspect_ratio_and_pads_at_the_top_left(self):
        source = ImageRecorder((100, 20))
        context = ImageContext(source)

        ImageResizePadStrategy().transform(context, {"width": 200, "height": 100})

        self.assertEqual(source.resize_size, (200, 40))
        self.assertEqual(context.image.size, (200, 100))
        self.assertEqual(context.image.paste_offset, (0, 0))

    def test_can_center_the_resized_image(self):
        source = ImageRecorder((100, 20))
        context = ImageContext(source)

        ImageResizePadStrategy().transform(
            context, {"width": 200, "height": 100, "alignment": "center"}
        )

        self.assertEqual(context.image.paste_offset, (0, 30))

    def test_rejects_an_unknown_alignment(self):
        with self.assertRaisesRegex(ValueError, "topLeft oder center"):
            ImageResizePadStrategy().transform(
                ImageContext(ImageRecorder((10, 10))),
                {"width": 20, "height": 20, "alignment": "bottomRight"},
            )


class ImageContext:
    def __init__(self, image):
        self.image = image
        self.image_module = ImageModule

    def require_image(self, _):
        return None


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
