import base64
import io
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy
from PIL import Image

from ml_test_support import REGISTRY, context, png_base64
from novooa_ml.model_input.worker import transform_payload


def output(value, *steps, inputs):
    ctx = context(inputs=inputs)
    return REGISTRY.run(value, [{"type": kind, "parameters": parameters} for kind, parameters in steps], ctx).value


def decoded_image(file):
    return Image.open(io.BytesIO(base64.b64decode(file["dataBase64"])))


class ApplyMaskTest(unittest.TestCase):
    """Freistellen: Maske des Modells als Alphakanal auf das gemerkte Originalbild."""

    def metadata_for(self, steps):
        payload = {
            "input": {"name": "bild", "dataType": "float32", "shape": [4, 4, 3], "transformations": steps},
            "source": {"type": "image", "dataBase64": png_base64(Image.new("RGB", (8, 4), (200, 100, 50)))},
        }
        return transform_payload(payload)["tensor"]["metadata"]

    def test_places_the_mask_as_alpha_of_the_original_through_the_letterbox(self):
        metadata = self.metadata_for([
            {"type": "image.keepSource", "parameters": {}},
            {"type": "image.resizePad", "parameters": {"width": 4, "height": 4, "alignment": "center"}},
        ])
        mask = numpy.zeros((1, 1, 4, 4), dtype=numpy.float32)
        mask[0, 0, 1:3, :2] = 1.0  # Linke Hälfte des eingepassten Bildes (Zeilen 1–2 ohne Rand).

        file = output(mask, ("image.applyMask", {"input": "bild"}), inputs={"bild": metadata})

        pixels = numpy.asarray(decoded_image(file))
        self.assertEqual(file["contentType"], "image/png")
        self.assertEqual(pixels.shape, (4, 8, 4))
        numpy.testing.assert_array_equal(pixels[..., 3], [[255] * 4 + [0] * 4] * 4)
        numpy.testing.assert_array_equal(pixels[0, 0, :3], [200, 100, 50])

    def test_reads_masks_in_bytes(self):
        metadata = self.metadata_for([{"type": "image.keepSource", "parameters": {}}, {"type": "image.resize", "parameters": {"width": 4, "height": 4}}])

        file = output(numpy.full((4, 4), 128.0), ("image.applyMask", {"input": "bild", "range": "byte"}), inputs={"bild": metadata})

        self.assertEqual(int(numpy.asarray(decoded_image(file))[0, 0, 3]), 128)

    def test_needs_the_source_kept_before_any_geometric_step(self):
        with self.assertRaisesRegex(ValueError, "image.keepSource muss vor Schritten stehen"):
            self.metadata_for([{"type": "image.resize", "parameters": {"width": 4, "height": 4}}, {"type": "image.keepSource", "parameters": {}}])
        metadata = self.metadata_for([{"type": "image.resize", "parameters": {"width": 4, "height": 4}}])
        with self.assertRaisesRegex(ValueError, "kein Quellbild \\(image.keepSource fehlt\\)"):
            output(numpy.zeros((4, 4)), ("image.applyMask", {"input": "bild"}), inputs={"bild": metadata})


if __name__ == "__main__":
    unittest.main()
