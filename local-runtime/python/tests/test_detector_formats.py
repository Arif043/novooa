import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy

from ml_test_support import REGISTRY, context
from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.pipeline_check import check_contract

CORNERS = {"left": 0, "top": 1, "right": 2, "bottom": 3}
CENTER = {"centerX": 0, "centerY": 1, "width": 2, "height": 3}


def suppress(rows, **parameters):
    step = {"type": "tensor.nonMaximumSuppression", "parameters": parameters}
    return REGISTRY.run(numpy.asarray(rows, dtype=numpy.float32), [step], context()).value


class BoxFormatTest(unittest.TestCase):
    def test_converts_center_boxes_into_corners(self):
        [detection] = suppress([[50, 40, 20, 10, 0.9]], box=CENTER, scoreIndex=4)

        self.assertEqual(detection["box"], {"left": 40.0, "top": 35.0, "right": 60.0, "bottom": 45.0})

    def test_scales_normalized_coordinates_into_the_model_image(self):
        [detection] = suppress([[0.5, 0.5, 0.25, 0.5, 0.9]], box=CENTER, scoreIndex=4, boxScale={"x": 640, "y": 320})

        self.assertEqual(detection["box"], {"left": 240.0, "top": 80.0, "right": 400.0, "bottom": 240.0})


class ClassScoreTest(unittest.TestCase):
    def test_picks_the_best_class_and_its_score_per_row(self):
        [detection] = suppress([[0, 0, 10, 10, 0.1, 0.7, 0.2]], box=CORNERS, classScores={"start": 4})

        self.assertEqual((detection["classIndex"], round(detection["score"], 5)), (1, 0.7))

    def test_limits_the_class_columns_and_multiplies_an_objectness_score(self):
        rows = [[0, 0, 10, 10, 0.5, 0.2, 0.8, 99.0]]

        [detection] = suppress(rows, box=CORNERS, objectnessIndex=4, classScores={"start": 5, "end": 7})

        self.assertEqual(detection["classIndex"], 1)
        self.assertAlmostEqual(detection["score"], 0.4, places=5)

    def test_suppresses_overlaps_only_within_a_class_by_default(self):
        rows = [[0, 0, 10, 10, 0.9, 0.1], [1, 1, 10, 10, 0.1, 0.8]]

        per_class = suppress(rows, box=CORNERS, classScores={"start": 4})
        across = suppress(rows, box=CORNERS, classScores={"start": 4}, classAware=False)

        self.assertEqual([item["classIndex"] for item in per_class], [0, 1])
        self.assertEqual(len(across), 1)

    def test_caps_the_number_of_detections(self):
        rows = [[index * 20, 0, index * 20 + 10, 10, 0.5 + index / 10] for index in range(4)]

        result = suppress(rows, box=CORNERS, scoreIndex=4, maxDetections=2)

        self.assertEqual([item["index"] for item in result], [3, 2])

    def test_keeps_the_plain_score_column_behaviour(self):
        result = suppress([[0, 0, 10, 10, 0.8], [1, 1, 10, 10, 0.9]], box=CORNERS, scoreIndex=4)

        self.assertEqual([item["index"] for item in result], [1])
        self.assertNotIn("classIndex", result[0])


class DetectorDefinitionErrorTest(unittest.TestCase):
    def test_needs_exactly_one_way_to_score_rows(self):
        with self.assertRaisesRegex(ValueError, "benötigt scoreIndex oder classScores"):
            suppress([[0, 0, 1, 1, 1]], box=CORNERS)
        with self.assertRaisesRegex(ValueError, "entweder scoreIndex oder classScores"):
            suppress([[0, 0, 1, 1, 1]], box=CORNERS, scoreIndex=4, classScores={"start": 4})

    def test_names_columns_outside_the_tensor(self):
        with self.assertRaisesRegex(ValueError, "außerhalb der Tensorbreite"):
            suppress([[0, 0, 1, 1, 1]], box=CORNERS, classScores={"start": 4, "end": 9})
        with self.assertRaisesRegex(ValueError, "außerhalb der Tensorbreite"):
            suppress([[0, 0, 1, 1]], box=CENTER, scoreIndex=4)

    def test_import_accepts_either_box_format_and_rejects_mixed_ones(self):
        def contract(box, **extra):
            return {"inputs": [], "outputs": [{"name": "boxen", "transformations": [
                {"type": "tensor.nonMaximumSuppression", "parameters": {"box": box, **extra}},
            ]}]}

        check_contract(contract(CENTER, classScores={"start": 4}, boxScale={"x": 640, "y": 640}), REGISTRY)
        # Das gemischte Objekt passt am ehesten zur Ecken-Form; benannt wird das fremde Feld.
        with self.assertRaisesRegex(ValueError, "Unbekannter Parameter box.centerY"):
            check_contract(contract({"left": 0, "centerY": 1, "right": 2, "bottom": 3}, scoreIndex=4), REGISTRY)
        with self.assertRaisesRegex(ValueError, "box erwartet ein Objekt mit left, top, right, bottom oder ein Objekt mit centerX"):
            check_contract(contract({"x": 0}, scoreIndex=4), REGISTRY)


class YoloStyleDetectorTest(unittest.TestCase):
    """Ausgang [1, 4 + Klassen, Anker] mit Mittelpunkt-Boxen, wie ihn YOLOv8 im 640er-Raster liefert."""

    def test_decodes_labels_and_maps_boxes_back_into_the_original_image(self):
        anchors = numpy.array([
            [96, 256, 64, 32, 0.05, 0.92],
            [97, 257, 64, 32, 0.04, 0.85],
            [400, 300, 40, 40, 0.70, 0.10],
        ], dtype=numpy.float32)
        raw = anchors.T[None]
        geometry = {"sourceWidth": 1000, "sourceHeight": 500, "scaleX": 0.64, "scaleY": 0.64, "offsetX": 0.0, "offsetY": 160.0}
        ctx = TransformationContext(numpy, inputs={"bild": {"geometry": geometry}}, resource_reader=lambda name: b"person\nkatze\n")

        result = REGISTRY.run(raw, [
            {"type": "tensor.squeeze", "parameters": {}},
            {"type": "tensor.transpose", "parameters": {"axes": [1, 0]}},
            {"type": "tensor.nonMaximumSuppression", "parameters": {"box": CENTER, "classScores": {"start": 4}, "scoreThreshold": 0.25}},
            {"type": "resource.lookup", "parameters": {"resource": "labels.txt", "key": "classIndex"}},
            {"type": "geometry.toSource", "parameters": {"input": "bild"}},
        ], ctx).value

        self.assertEqual([(item["label"], item["index"]) for item in result], [("katze", 0), ("person", 2)])
        self.assertEqual({key: round(value, 3) for key, value in result[0]["box"].items()},
                         {"left": 100.0, "top": 125.0, "right": 200.0, "bottom": 175.0})


if __name__ == "__main__":
    unittest.main()
