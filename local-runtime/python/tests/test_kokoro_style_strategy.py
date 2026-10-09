import io
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy
from novooa_ml.input_transforms.text.kokoro_style import style_for


class KokoroStyleStrategyTest(unittest.TestCase):
    def test_selects_a_style_by_token_count(self):
        resource = voice_resource()

        style = style_for(resource, "martin", 1, numpy)

        self.assertEqual(style.shape, (1, 256))
        self.assertEqual(style[0, 0], 256)


def voice_resource():
    voices = {"martin": numpy.arange(3 * 256, dtype=numpy.float32).reshape(3, 1, 256)}
    buffer = io.BytesIO()
    numpy.savez(buffer, **voices)
    return buffer.getvalue()


if __name__ == "__main__":
    unittest.main()
