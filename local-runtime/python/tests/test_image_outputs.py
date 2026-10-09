import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import base64
import io

import numpy
from PIL import Image

from ml_test_support import REGISTRY, png_base64
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.model_output.worker import transform_outputs
from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.pipeline_check import check_output_pipeline

# Quelle 1000×500, ins 640er-Raster mittig eingepasst: Faktor 0,64, Rand oben 160.
LETTERBOX = {"sourceWidth": 1000, "sourceHeight": 500, "scaleX": 0.64, "scaleY": 0.64, "offsetX": 0.0, "offsetY": 160.0}


def output(value, *steps, inputs=None):
    ctx = TransformationContext(numpy, image_module=Image, inputs=inputs or {"bild": {"geometry": LETTERBOX}})
    return REGISTRY.run(value, [{"type": kind, "parameters": parameters} for kind, parameters in steps], ctx).value


def decoded_image(file):
    return Image.open(io.BytesIO(base64.b64decode(file["dataBase64"])))


class GeometryToSourceTest(unittest.TestCase):
    def test_maps_detection_boxes_back_into_the_original_image(self):
        detections = [{"index": 0, "score": 0.9, "box": {"left": 64.0, "top": 192.0, "right": 128.0, "bottom": 224.0}}]

        result = output(detections, ("geometry.toSource", {"input": "bild"}))

        self.assertEqual(result[0]["box"], {"left": 100.0, "top": 50.0, "right": 200.0, "bottom": 100.0})
        self.assertEqual(result[0]["score"], 0.9)

    def test_maps_region_bounds_and_rounds_to_pixels(self):
        regions = [{"bounds": {"left": 64, "top": 192, "width": 64, "height": 32}, "pixelCount": 10}]

        result = output(regions, ("geometry.toSource", {"input": "bild"}))

        self.assertEqual(result[0]["bounds"], {"left": 100, "top": 50, "width": 100, "height": 50})
        self.assertEqual(result[0]["pixelCount"], 10)

    def test_clips_to_the_original_image_unless_disabled(self):
        detections = [{"index": 0, "score": 1.0, "box": {"left": -64.0, "top": 100.0, "right": 700.0, "bottom": 200.0}}]

        clipped = output(detections, ("geometry.toSource", {"input": "bild"}))[0]["box"]
        raw = output(detections, ("geometry.toSource", {"input": "bild", "clip": False}))[0]["box"]

        self.assertEqual(clipped, {"left": 0.0, "top": 0.0, "right": 1000.0, "bottom": 62.5})
        self.assertEqual(raw["left"], -100.0)

    def test_names_unknown_or_irreversible_inputs(self):
        with self.assertRaisesRegex(ValueError, "geometry.toSource: Der Eingang foto liefert keine Bildgeometrie"):
            output([], ("geometry.toSource", {"input": "foto"}))
        with self.assertRaisesRegex(ValueError, "lässt sich nicht zurückrechnen"):
            output([], ("geometry.toSource", {"input": "bild"}), inputs={"bild": {"geometry": None}})


class MaskToSourceTest(unittest.TestCase):
    # Quelle 4×2 mittig in 4×4: Faktor 1, Rand oben 1.
    PADDED = {"bild": {"geometry": {"sourceWidth": 4, "sourceHeight": 2, "scaleX": 1.0, "scaleY": 1.0, "offsetX": 0.0, "offsetY": 1.0}}}

    def model_mask(self):
        return numpy.arange(16).reshape(4, 4)

    def test_maps_a_mask_back_and_drops_the_padding(self):
        result = output(self.model_mask(), ("mask.toSource", {"input": "bild"}), inputs=self.PADDED)

        self.assertEqual(result.tolist(), [[4, 5, 6, 7], [8, 9, 10, 11]])

    def test_handles_channels_in_either_layout(self):
        first = output(numpy.stack([self.model_mask()] * 2), ("mask.toSource", {"input": "bild"}), inputs=self.PADDED)
        last = output(numpy.stack([self.model_mask()] * 2, axis=-1), ("mask.toSource", {"input": "bild", "layout": "channelsLast"}), inputs=self.PADDED)

        self.assertEqual(first.shape, (2, 2, 4))
        self.assertEqual(last.shape, (2, 4, 2))
        self.assertEqual(last[1, 3].tolist(), [11, 11])

    def test_fills_areas_outside_the_model_image(self):
        shrunk = {"bild": {"geometry": {"sourceWidth": 4, "sourceHeight": 1, "scaleX": 0.5, "scaleY": 1.0, "offsetX": 3.0, "offsetY": 0.0}}}

        result = output(numpy.ones((1, 4)), ("mask.toSource", {"input": "bild", "fill": -1}), inputs=shrunk)

        self.assertEqual(result.tolist(), [[1, 1, -1, -1]])

    def test_squeezes_a_leading_batch_dimension(self):
        self.assertEqual(output(self.model_mask()[None, None], ("mask.toSource", {"input": "bild"}), inputs=self.PADDED).shape, (2, 4))


class ImageEncodeTest(unittest.TestCase):
    def test_encodes_grayscale_and_clips_values(self):
        file = output(numpy.array([[0.0, 300.0], [-5.0, 128.4]]), ("image.encode", {}))

        image = decoded_image(file)
        self.assertEqual((file["contentType"], file["fileName"], image.mode), ("image/png", "modell-ausgabe.png", "L"))
        self.assertEqual(numpy.asarray(image).tolist(), [[0, 255], [0, 128]])

    def test_encodes_color_in_both_layouts(self):
        rgb = numpy.zeros((2, 3, 3))
        rgb[..., 0] = 255
        last = decoded_image(output(rgb, ("image.encode", {})))
        first = decoded_image(output(numpy.moveaxis(rgb, -1, 0)[None], ("image.encode", {"layout": "channelsFirst"})))

        self.assertEqual((last.mode, last.size, last.getpixel((0, 0))), ("RGB", (3, 2), (255, 0, 0)))
        self.assertEqual(first.getpixel((2, 1)), (255, 0, 0))

    def test_colors_class_indices_with_a_palette(self):
        classes = numpy.array([[0, 1], [2, 1]])

        image = decoded_image(output(classes, ("image.encode", {"palette": [[0, 0, 0], [255, 0, 0], [0, 0, 255]]})))

        self.assertEqual([image.getpixel((x, y)) for y in range(2) for x in range(2)], [(0, 0, 0), (255, 0, 0), (0, 0, 255), (255, 0, 0)])

    def test_supports_jpeg_and_a_file_name(self):
        file = output(numpy.zeros((4, 4)), ("image.encode", {"format": "jpeg", "fileName": "tiefe.jpg"}))

        self.assertEqual((file["contentType"], file["fileName"], decoded_image(file).format), ("image/jpeg", "tiefe.jpg", "JPEG"))

    def test_rejects_unsupported_shapes_and_palette_indices(self):
        with self.assertRaisesRegex(ValueError, "image.encode erwartet"):
            output(numpy.zeros((2, 2, 5)), ("image.encode", {}))
        with self.assertRaisesRegex(ValueError, "Klassenindex 3 liegt außerhalb der Palette"):
            output(numpy.array([[3]]), ("image.encode", {"palette": [[0, 0, 0]]}))


class ImageOutputChainTest(unittest.TestCase):
    def test_detections_and_regions_flow_into_geometry_to_source(self):
        steps = [
            {"type": "tensor.nonMaximumSuppression", "parameters": {}},
            {"type": "geometry.toSource", "parameters": {}},
        ]
        check_output_pipeline("boxen", steps, REGISTRY)
        check_output_pipeline("maske", [{"type": "mask.connectedComponents", "parameters": {}}, steps[1]], REGISTRY)
        with self.assertRaisesRegex(ValueError, "geometry.toSource erwartet regions oder detections, erhält tensor"):
            check_output_pipeline("roh", [steps[1]], REGISTRY)

    def test_a_box_travels_from_the_input_through_the_model_back_into_the_original(self):
        payload = {
            "input": {"name": "bild", "dataType": "float32", "shape": [640, 640, 3], "transformations": [
                {"type": "image.resizePad", "parameters": {"width": 640, "height": 640, "alignment": "center"}},
            ]},
            "source": {"type": "image", "dataBase64": png_base64(Image.new("RGB", (1000, 500)))},
        }
        encoded = transform_payload(payload)["tensor"]
        model_rows = numpy.array([[64, 192, 128, 224, 0.9]], dtype=numpy.float32)
        definitions = [{"name": "boxen", "transformations": [
            {"type": "tensor.nonMaximumSuppression", "parameters": {"box": {"left": 0, "top": 1, "right": 2, "bottom": 3}, "scoreIndex": 4}},
            {"type": "geometry.toSource", "parameters": {"input": "bild"}},
        ]}]

        [result] = transform_outputs([("boxen", model_rows)], definitions, numpy, input_metadata={"bild": encoded["metadata"]})

        box = result["transformationValues"]["tensor"][0]["box"]
        self.assertEqual({key: round(value, 3) for key, value in box.items()}, {"left": 100.0, "top": 50.0, "right": 200.0, "bottom": 100.0})


if __name__ == "__main__":
    unittest.main()
