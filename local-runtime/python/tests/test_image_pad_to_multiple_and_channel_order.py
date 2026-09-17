import sys
import unittest
from pathlib import Path

import numpy

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.input_transforms.image_pad_to_multiple_strategy import ImagePadToMultipleStrategy
from novooa_ml.input_transforms.tensor_channel_order_strategy import TensorChannelOrderStrategy


class ImagePadToMultipleStrategyTest(unittest.TestCase):
    def test_pads_only_the_right_and_bottom_edges(self):
        source = ImageRecorder((65, 33))
        context = ImageContext(source)

        ImagePadToMultipleStrategy().transform(context, {"multiple": 32})

        self.assertEqual(context.image.size, (96, 64))
        self.assertEqual(context.image.paste_offset, (0, 0))

    def test_does_not_allocate_when_already_aligned(self):
        source = ImageRecorder((64, 32))
        context = ImageContext(source)

        ImagePadToMultipleStrategy().transform(context, {"multiple": 32})

        self.assertIs(context.image, source)


class TensorChannelOrderStrategyTest(unittest.TestCase):
    def test_reorders_channels_before_layout_conversion(self):
        context = TensorContext(numpy.array([[[1, 2, 3]]]))

        TensorChannelOrderStrategy().transform(context, {"order": [2, 1, 0]})

        self.assertEqual(context.tensor.tolist(), [[[3, 2, 1]]])

    def test_rejects_an_incomplete_permutation(self):
        context = TensorContext(numpy.zeros((1, 1, 3)))

        with self.assertRaisesRegex(ValueError, "jeden Kanal genau einmal"):
            TensorChannelOrderStrategy().transform(context, {"order": [0, 1]})


class ImageContext:
    def __init__(self, image):
        self.image = image
        self.image_module = ImageModule

    def require_image(self, _):
        return None


class TensorContext:
    def __init__(self, tensor):
        self.tensor = tensor

    def tensor_array(self):
        return self.tensor


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
