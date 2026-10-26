import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy
from PIL import Image

from ml_test_support import context, png_base64, run
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.model_output.worker import transform_outputs


class KeypointsFromRowsTest(unittest.TestCase):
    def test_reads_movenet_rows_of_y_x_score_in_model_pixels(self):
        """MoveNet liefert `[1, 1, 17, 3]` mit (y, x, score) normiert auf die Eingabegröße."""
        rows = numpy.zeros((1, 1, 17, 3), dtype=numpy.float32)
        rows[0, 0, 0] = [0.25, 0.5, 0.9]
        rows[0, 0, 16] = [1.0, 0.0, 0.1]

        points = run(rows, ("keypoints.fromRows", {"x": 1, "y": 0, "score": 2, "scale": {"x": 192, "y": 192}}))

        self.assertEqual(len(points), 17)
        self.assertEqual(points[0], {"index": 0, "x": 96.0, "y": 48.0, "score": numpy.float32(0.9).item()})
        self.assertEqual((points[16]["x"], points[16]["y"]), (0.0, 192.0))

    def test_omits_the_score_without_a_score_column(self):
        [point] = run(numpy.array([[3.0, 4.0]]), ("keypoints.fromRows", {"x": 0, "y": 1}))

        self.assertEqual(point, {"index": 0, "x": 3.0, "y": 4.0})

    def test_rejects_a_column_outside_the_row(self):
        with self.assertRaisesRegex(ValueError, "außerhalb der Breite 2"):
            run(numpy.zeros((3, 2)), ("keypoints.fromRows", {"x": 0, "y": 2}))


class KeypointsFromHeatmapsTest(unittest.TestCase):
    def heatmaps(self):
        maps = numpy.zeros((2, 3, 4), dtype=numpy.float32)
        maps[0, 2, 1] = 0.8
        maps[1, 0, 3] = 0.6
        return maps

    def test_takes_the_maximum_of_each_map_scaled_by_the_stride(self):
        points = run(self.heatmaps()[numpy.newaxis], ("keypoints.fromHeatmaps", {"stride": {"x": 4, "y": 4}}))

        self.assertEqual([(p["x"], p["y"]) for p in points], [(4.0, 8.0), (12.0, 0.0)])
        self.assertAlmostEqual(points[0]["score"], 0.8, places=6)

    def test_reads_maps_with_the_channels_last(self):
        maps = numpy.moveaxis(self.heatmaps(), 0, -1)

        points = run(maps, ("keypoints.fromHeatmaps", {"layout": "channelsLast"}))

        self.assertEqual([(p["x"], p["y"]) for p in points], [(1.0, 2.0), (3.0, 0.0)])


class KeypointsFromSimccTest(unittest.TestCase):
    """Referenz: MMPose `get_simcc_maximum` — Argmax je Achse / split_ratio, Score = kleineres Maximum."""

    def test_combines_x_and_y_distributions_from_two_outputs(self):
        simcc_x = numpy.zeros((1, 2, 8), dtype=numpy.float32)
        simcc_y = numpy.zeros((1, 2, 6), dtype=numpy.float32)
        simcc_x[0, 0, 5], simcc_y[0, 0, 3] = 0.9, 0.7
        simcc_x[0, 1, 2], simcc_y[0, 1, 1] = 0.4, 0.8

        points = run(simcc_x, ("keypoints.fromSimcc", {"yOutput": "simcc_y"}), ctx=context(outputs={"simcc_y": simcc_y}))

        self.assertEqual([(p["x"], p["y"]) for p in points], [(2.5, 1.5), (1.0, 0.5)])
        self.assertAlmostEqual(points[0]["score"], 0.7, places=6)
        self.assertAlmostEqual(points[1]["score"], 0.4, places=6)

    def test_rejects_a_different_number_of_keypoints_per_axis(self):
        with self.assertRaisesRegex(ValueError, "2 x- und 3 y-Verteilungen"):
            run(numpy.zeros((2, 8)), ("keypoints.fromSimcc", {"yOutput": "y"}), ctx=context(outputs={"y": numpy.zeros((3, 6))}))


class KeypointGeometryTest(unittest.TestCase):
    def test_maps_keypoints_from_a_letterboxed_input_back_into_the_original(self):
        payload = {
            "input": {"name": "bild", "dataType": "float32", "shape": [100, 100, 3], "transformations": [
                {"type": "image.resizePad", "parameters": {"width": 100, "height": 100, "alignment": "center"}},
            ]},
            "source": {"type": "image", "dataBase64": png_base64(Image.new("RGB", (200, 100)))},
        }
        metadata = transform_payload(payload)["tensor"]["metadata"]
        definitions = [{"name": "punkte", "transformations": [
            {"type": "keypoints.fromRows", "parameters": {"x": 0, "y": 1}},
            {"type": "geometry.toSource", "parameters": {"input": "bild"}},
        ]}]

        [output] = transform_outputs([("punkte", numpy.array([[50.0, 50.0], [0.0, 25.0]]))], definitions, numpy, input_metadata={"bild": metadata})

        # 200 × 100 → Faktor 0.5, oben und unten je 25 Pixel Rand.
        self.assertEqual([(p["x"], p["y"]) for p in output["transformationValues"]["tensor"]], [(100.0, 50.0), (0.0, 0.0)])


if __name__ == "__main__":
    unittest.main()
