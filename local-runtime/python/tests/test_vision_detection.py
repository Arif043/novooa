import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy

from ml_test_support import run

BOX = {"left": 0, "top": 1, "right": 2, "bottom": 3}


def detections(*rows):
    return numpy.array(rows, dtype=numpy.float32)


class NonMaximumSuppressionTest(unittest.TestCase):
    def suppress(self, tensor, **parameters):
        return run(tensor, ("tensor.nonMaximumSuppression", {"box": BOX, "scoreIndex": 4, **parameters}))

    def test_keeps_the_best_of_overlapping_boxes(self):
        result = self.suppress(detections(
            [0, 0, 10, 10, 0.8],
            [1, 1, 10, 10, 0.9],
            [20, 20, 30, 30, 0.7],
        ))

        self.assertEqual([item["index"] for item in result], [1, 2])
        self.assertEqual(result[0]["box"], {"left": 1.0, "top": 1.0, "right": 10.0, "bottom": 10.0})

    def test_keeps_boxes_whose_overlap_stays_below_the_threshold(self):
        tensor = detections([0, 0, 10, 10, 0.9], [5, 0, 15, 10, 0.8])

        self.assertEqual(len(self.suppress(tensor, iouThreshold=0.5)), 2)
        self.assertEqual(len(self.suppress(tensor, iouThreshold=0.2)), 1)

    def test_drops_detections_below_the_score_threshold(self):
        result = self.suppress(detections([0, 0, 1, 1, 0.2], [5, 5, 6, 6, 0.6]), scoreThreshold=0.5)

        self.assertEqual([item["index"] for item in result], [1])

    def test_rejects_invalid_definitions(self):
        tensor = detections([0, 0, 1, 1, 0.5])
        with self.assertRaisesRegex(ValueError, "benötigt box"):
            run(tensor, ("tensor.nonMaximumSuppression", {"scoreIndex": 4}))
        with self.assertRaisesRegex(ValueError, "außerhalb der Tensorbreite"):
            self.suppress(tensor, scoreIndex=9)
        with self.assertRaisesRegex(ValueError, "iouThreshold"):
            self.suppress(tensor, iouThreshold=1.5)
        with self.assertRaisesRegex(ValueError, "Erkennungsbox ist ungültig"):
            self.suppress(detections([5, 0, 1, 1, 0.5]))
        with self.assertRaisesRegex(ValueError, "erkennungen, werte"):
            self.suppress(numpy.zeros(5))


class ConnectedComponentsTest(unittest.TestCase):
    def test_diagonal_pixels_form_separate_regions(self):
        mask = numpy.array([[[1, 0], [0, 1]]])

        regions = run(mask, ("mask.connectedComponents", {}))

        self.assertEqual(len(regions), 2)
        self.assertTrue(all(region["pixelCount"] == 1 for region in regions))

    def test_reports_bounds_and_pixel_count_and_filters_small_regions(self):
        mask = numpy.array([[1, 1, 0, 0], [1, 0, 0, 1], [0, 0, 0, 0]])

        regions = run(mask, ("mask.connectedComponents", {"minimumPixels": 2}))

        self.assertEqual(regions, [{"bounds": {"left": 0, "top": 0, "width": 2, "height": 2}, "pixelCount": 3}])

    def test_rejects_batches_and_invalid_minimums(self):
        with self.assertRaisesRegex(ValueError, "einzelne zweidimensionale Maske"):
            run(numpy.zeros((2, 3, 3)), ("mask.connectedComponents", {}))
        with self.assertRaisesRegex(ValueError, "minimumPixels"):
            run(numpy.zeros((3, 3)), ("mask.connectedComponents", {"minimumPixels": -1}))


class RegionChainTest(unittest.TestCase):
    def test_regions_flow_into_row_merging_and_scaling(self):
        mask = numpy.zeros((4, 8))
        mask[1, 0:2] = 1
        mask[1, 4:6] = 1

        rows = run(
            mask,
            ("mask.connectedComponents", {}),
            ("geometry.mergeRows", {}),
            ("geometry.scaleBounds", {"scaleX": 10, "scaleY": 10}),
        )

        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["bounds"], {"left": 0, "top": 10, "width": 60, "height": 10})
        self.assertEqual(rows[0]["memberCount"], 2)


if __name__ == "__main__":
    unittest.main()
