import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import io

import numpy
from PIL import Image

from ml_test_support import REGISTRY, context, png_base64
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.tensor_codec import decode_tensor
from novooa_ml.transformations.geometry import start_geometry


def geometry_after(image, *steps):
    ctx = context()
    start_geometry(ctx, image)
    REGISTRY.run(image, [{"type": kind, "parameters": parameters} for kind, parameters in steps], ctx)
    return ctx.metadata["geometry"]


def assert_geometry(test, geometry, scale, offset, source):
    test.assertEqual((geometry["sourceWidth"], geometry["sourceHeight"]), source)
    test.assertAlmostEqual(geometry["scaleX"], scale[0])
    test.assertAlmostEqual(geometry["scaleY"], scale[1])
    test.assertAlmostEqual(geometry["offsetX"], offset[0])
    test.assertAlmostEqual(geometry["offsetY"], offset[1])


class GeometryTrackingTest(unittest.TestCase):
    def test_starts_as_identity_of_the_source_image(self):
        assert_geometry(self, geometry_after(Image.new("RGB", (100, 50))), (1, 1), (0, 0), (100, 50))

    def test_resize_scales_each_axis(self):
        geometry = geometry_after(Image.new("RGB", (100, 50)), ("image.resize", {"width": 200, "height": 25}))

        assert_geometry(self, geometry, (2, 0.5), (0, 0), (100, 50))

    def test_resize_pad_scales_uniformly_and_shifts_when_centered(self):
        image = Image.new("RGB", (100, 50))
        centered = geometry_after(image, ("image.resizePad", {"width": 200, "height": 200, "alignment": "center"}))
        top_left = geometry_after(image, ("image.resizePad", {"width": 200, "height": 200}))

        assert_geometry(self, centered, (2, 2), (0, 50), (100, 50))
        assert_geometry(self, top_left, (2, 2), (0, 0), (100, 50))

    def test_resize_shorter_side_and_center_crop(self):
        geometry = geometry_after(
            Image.new("RGB", (400, 200)),
            ("image.resizeShorterSide", {"size": 100}),
            ("image.centerCrop", {"width": 100, "height": 100}),
        )

        assert_geometry(self, geometry, (0.5, 0.5), (-50, 0), (400, 200))

    def test_crop_shifts_in_the_coordinates_reached_so_far(self):
        crop_then_resize = geometry_after(
            Image.new("RGB", (100, 100)),
            ("image.crop", {"left": 10, "top": 5, "width": 50, "height": 50}),
            ("image.resize", {"width": 100, "height": 100}),
        )
        resize_then_crop = geometry_after(
            Image.new("RGB", (100, 100)),
            ("image.resize", {"width": 200, "height": 200}),
            ("image.crop", {"left": 10, "top": 5, "width": 50, "height": 50}),
        )

        assert_geometry(self, crop_then_resize, (2, 2), (-20, -10), (100, 100))
        assert_geometry(self, resize_then_crop, (2, 2), (-10, -5), (100, 100))

    def test_resize_height_pad_centers_narrow_lines(self):
        geometry = geometry_after(
            Image.new("L", (20, 10)),
            ("image.resizeHeightPad", {"height": 20, "width": 100, "alignment": "center"}),
        )

        assert_geometry(self, geometry, (2, 2), (30, 0), (20, 10))

    def test_steps_without_geometric_effect_keep_it(self):
        geometry = geometry_after(
            Image.new("RGB", (30, 20)),
            ("image.decode", {"colorSpace": "grayscale"}),
            ("image.padToMultiple", {"multiple": 32}),
            ("tensor.scale", {"factor": 2}),
        )

        assert_geometry(self, geometry, (1, 1), (0, 0), (30, 20))

    def test_perspective_crops_cannot_be_inverted(self):
        geometry = geometry_after(
            Image.new("RGB", (20, 20)),
            ("image.perspectiveCrop", {"points": [0, 0, 0, 10, 10, 10, 10, 0], "width": 10, "height": 10}),
        )

        self.assertIsNone(geometry)

    def test_exif_transpose_makes_the_turned_photo_the_source(self):
        exif = Image.Exif()
        exif[0x0112] = 6
        buffer = io.BytesIO()
        Image.new("RGB", (40, 20)).save(buffer, format="JPEG", exif=exif)
        buffer.seek(0)

        geometry = geometry_after(Image.open(buffer), ("image.exifTranspose", {}), ("image.resize", {"width": 10, "height": 20}))

        assert_geometry(self, geometry, (0.5, 0.5), (0, 0), (20, 40))


class GeometryTransportTest(unittest.TestCase):
    def test_the_encoded_input_carries_its_geometry(self):
        payload = {
            "input": {"name": "bild", "dataType": "float32", "shape": [3, 4, 4], "transformations": [
                {"type": "image.resizePad", "parameters": {"width": 4, "height": 4, "alignment": "center"}},
                {"type": "tensor.layout", "parameters": {"order": "channelsFirst"}},
            ]},
            "source": {"type": "image", "dataBase64": png_base64(Image.new("RGB", (8, 4)))},
        }

        encoded = transform_payload(payload)["tensor"]

        self.assertEqual(encoded["metadata"]["geometry"], {
            "sourceWidth": 8, "sourceHeight": 4, "scaleX": 0.5, "scaleY": 0.5, "offsetX": 0.0, "offsetY": 1.0,
        })

    def test_non_image_inputs_carry_no_geometry(self):
        payload = {
            "input": {"name": "zahl", "dataType": "float32", "shape": [1], "transformations": [{"type": "number.toTensor", "parameters": {}}]},
            "source": {"type": "number", "value": 2},
        }

        self.assertNotIn("metadata", transform_payload(payload)["tensor"])



class SizeTensorTest(unittest.TestCase):
    """Hilfseingänge wie `im_shape` und `scale_factor` der Paddle-Detektoren, als abgeleiteter Eingang."""

    def size_tensor(self, values, steps):
        payload = {
            "input": {"name": "scale_factor", "dataType": "float32", "shape": [1, len(values)], "transformations": [
                *steps, {"type": "image.sizeTensor", "parameters": {"values": values}},
            ]},
            "source": {"type": "image", "dataBase64": png_base64(Image.new("RGB", (1000, 500)))},
        }
        return decode_tensor(transform_payload(payload)["tensor"], numpy)

    def test_delivers_model_size_and_scale_after_a_letterbox(self):
        steps = [{"type": "image.resizePad", "parameters": {"width": 640, "height": 640, "alignment": "center"}}]

        tensor = self.size_tensor(["height", "width", "scaleY", "scaleX"], steps)

        numpy.testing.assert_allclose(tensor, [[640, 640, 0.64, 0.64]], rtol=1e-6)

    def test_delivers_the_original_size(self):
        steps = [{"type": "image.resize", "parameters": {"width": 320, "height": 320}}]

        numpy.testing.assert_allclose(self.size_tensor(["sourceHeight", "sourceWidth"], steps), [[500, 1000]])

    def test_has_no_scale_after_a_perspective_crop(self):
        steps = [{"type": "image.perspectiveCrop", "parameters": {"points": [0, 0, 10, 0, 10, 10, 0, 10], "width": 8, "height": 8}}]

        with self.assertRaisesRegex(ValueError, "scaleX lässt sich nach einem nicht umkehrbaren Bildschritt"):
            self.size_tensor(["scaleX"], steps)


if __name__ == "__main__":
    unittest.main()
