import sys
import unittest
from pathlib import Path

import numpy

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.input_transforms.image.pad_to_multiple import ImagePadToMultipleStrategy
from novooa_ml.input_transforms.tensor.channel_order import TensorChannelOrderStrategy
from novooa_ml.transformations.context import TransformationContext


class ImagePadToMultipleStrategyTest(unittest.TestCase):
    def test_pads_only_the_right_and_bottom_edges(self):
        source = ImageRecorder((65, 33))
        context = ImageContext(source)

        context.image = ImagePadToMultipleStrategy().transform(context.image, {"multiple": 32}, context)

        self.assertEqual(context.image.size, (96, 64))
        self.assertEqual(context.image.paste_offset, (0, 0))

    def test_does_not_allocate_when_already_aligned(self):
        source = ImageRecorder((64, 32))
        context = ImageContext(source)

        context.image = ImagePadToMultipleStrategy().transform(context.image, {"multiple": 32}, context)

        self.assertIs(context.image, source)


class TensorChannelOrderStrategyTest(unittest.TestCase):
    def test_reorders_channels_before_layout_conversion(self):
        tensor = TensorChannelOrderStrategy().transform(
            numpy.array([[[1, 2, 3]]]), {"order": [2, 1, 0]}, TransformationContext(numpy)
        )

        self.assertEqual(tensor.tolist(), [[[3, 2, 1]]])

    def test_rejects_an_incomplete_permutation(self):
        with self.assertRaisesRegex(ValueError, "jeden Kanal genau einmal"):
            TensorChannelOrderStrategy().transform(
                numpy.zeros((1, 1, 3)), {"order": [0, 1]}, TransformationContext(numpy)
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


class Canvas:
    def __init__(self, size):
        self.size = size
        self.paste_offset = None

    def paste(self, _, offset):
        self.paste_offset = offset


class ImageModule:
    @staticmethod
    def new(_, size, __):
        return Canvas(size)


if __name__ == "__main__":
    unittest.main()
