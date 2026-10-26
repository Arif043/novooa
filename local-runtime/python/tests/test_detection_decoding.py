import json
import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy

from ml_test_support import context, run

CENTER_BOX = {"centerX": 0, "centerY": 1, "width": 2, "height": 3}


def grid_rows(count):
    return numpy.zeros((count, 6), dtype=numpy.float32)


class DecodeGridTest(unittest.TestCase):
    """Referenz: YOLOX `decode_outputs` — (x + Spalte) × Stride, exp(w) × Stride, Zellen zeilenweise je Stride."""

    parameters = {"strides": [2, 4], "width": 8, "height": 4, "box": CENTER_BOX}

    def test_decodes_centers_and_sizes_per_cell_and_stride(self):
        rows = grid_rows(10)  # Stride 2: 4 × 2 Zellen, Stride 4: 2 × 1 Zellen.
        rows[5] = [0.5, 0.25, math.log(3), 0.0, 0.9, 0.1]  # Stride 2, Zeile 1, Spalte 1.
        rows[9] = [0.0, 0.5, 0.0, math.log(2), 0.8, 0.2]   # Stride 4, Zeile 0, Spalte 1.

        decoded = run(rows[numpy.newaxis], ("tensor.decodeGrid", self.parameters))

        numpy.testing.assert_allclose(decoded[5, :4], [3.0, 2.5, 6.0, 2.0], rtol=1e-6)
        numpy.testing.assert_allclose(decoded[9, :4], [4.0, 2.0, 4.0, 8.0], rtol=1e-6)
        numpy.testing.assert_allclose(decoded[5, 4:], [0.9, 0.1], rtol=1e-6)

    def test_decodes_linear_sizes(self):
        rows = grid_rows(10)
        rows[0] = [0.0, 0.0, 1.5, 2.0, 0.0, 0.0]

        decoded = run(rows, ("tensor.decodeGrid", {**self.parameters, "sizeEncoding": "linear"}))

        numpy.testing.assert_allclose(decoded[0, :4], [0.0, 0.0, 3.0, 4.0])

    def test_leaves_the_input_tensor_unchanged(self):
        rows = grid_rows(10)

        run(rows, ("tensor.decodeGrid", self.parameters))

        self.assertEqual(float(rows.sum()), 0.0)

    def test_rejects_a_row_count_that_does_not_fit_the_grid(self):
        with self.assertRaisesRegex(ValueError, "10 Zellen, der Tensor 9 Zeilen"):
            run(grid_rows(9), ("tensor.decodeGrid", self.parameters))

    def test_rejects_an_input_size_not_divisible_by_a_stride(self):
        with self.assertRaisesRegex(ValueError, "nicht durch den Stride 3 teilbar"):
            run(grid_rows(10), ("tensor.decodeGrid", {**self.parameters, "strides": [3]}))


def anchor_context(anchors):
    return context(resource_reader=lambda name: json.dumps(anchors).encode("utf-8"))


class DecodeAnchorsTest(unittest.TestCase):
    def test_decodes_ssd_boxes_with_variances(self):
        """Referenz: SSD `decode` — a_c + d × 0.1 × a_size, a_size × exp(d × 0.2)."""
        rows = numpy.array([[1.0, -1.0, math.log(2) / 0.2, 0.0, 0.7]], dtype=numpy.float32)

        decoded = run(rows, ("tensor.decodeAnchors", {"anchors": "anker", "box": CENTER_BOX}), ctx=anchor_context([[0.5, 0.5, 0.2, 0.4]]))

        numpy.testing.assert_allclose(decoded[0], [0.52, 0.46, 0.4, 0.4, 0.7], rtol=1e-5)

    def test_decodes_blazeface_boxes_linearly(self):
        """Referenz: MediaPipe — Rohwert / 128 × Ankergröße + Ankermitte, Größe linear."""
        rows = numpy.array([[12.8, -6.4, 25.6, 32.0]], dtype=numpy.float32)
        parameters = {"anchors": "anker", "box": CENTER_BOX, "variances": [1 / 128, 1 / 128], "sizeEncoding": "linear"}

        decoded = run(rows, ("tensor.decodeAnchors", parameters), ctx=anchor_context([[0.25, 0.75, 1.0, 1.0]]))

        numpy.testing.assert_allclose(decoded[0], [0.35, 0.70, 0.2, 0.25], rtol=1e-5)

    def test_rejects_anchors_that_do_not_match_the_rows(self):
        with self.assertRaisesRegex(ValueError, "1 Anker passen nicht zu 2 Zeilen"):
            run(numpy.zeros((2, 4)), ("tensor.decodeAnchors", {"anchors": "anker", "box": CENTER_BOX}), ctx=anchor_context([[0, 0, 1, 1]]))

    def test_rejects_a_resource_without_four_values_per_anchor(self):
        with self.assertRaisesRegex(ValueError, "je Anker \\[cx, cy, w, h\\]"):
            run(numpy.zeros((1, 4)), ("tensor.decodeAnchors", {"anchors": "anker", "box": CENTER_BOX}), ctx=anchor_context([[0, 0, 1]]))


CORNERS = {"left": 2, "top": 3, "right": 4, "bottom": 5}


class SuppressionOptionsTest(unittest.TestCase):
    """Erweiterungen der NMS für Zeilen `[klasse, score, x1, y1, x2, y2]` und Logits."""

    rows = numpy.array([
        [0, 0.9, 0, 0, 10, 10],
        [1, 0.8, 1, 1, 10, 10],
        [0, 0.7, 1, 1, 10, 10],
    ], dtype=numpy.float32)

    def test_reads_the_class_from_a_column_and_suppresses_per_class(self):
        result = run(self.rows, ("tensor.nonMaximumSuppression", {"box": CORNERS, "scoreIndex": 1, "classColumn": 0}))

        self.assertEqual([(item["index"], item["classIndex"]) for item in result], [(0, 0), (1, 1)])

    def test_keeps_every_detection_without_suppression(self):
        result = run(self.rows, ("tensor.nonMaximumSuppression", {"box": CORNERS, "scoreIndex": 1, "suppress": False}))

        self.assertEqual([item["index"] for item in result], [0, 1, 2])

    def test_turns_class_logits_into_a_softmax_distribution(self):
        logits = numpy.array([[0, 0, 1, 1, 2.0, 0.0, -1.0]], dtype=numpy.float32)
        parameters = {"box": {"left": 0, "top": 1, "right": 2, "bottom": 3}, "classScores": {"start": 4}, "scoreActivation": "softmax"}

        [result] = run(logits, ("tensor.nonMaximumSuppression", parameters))

        expected = math.exp(2.0) / (math.exp(2.0) + math.exp(0.0) + math.exp(-1.0))
        self.assertAlmostEqual(result["score"], expected, places=6)

    def test_applies_a_sigmoid_to_a_single_score_column(self):
        [result] = run(self.rows[:1] * [1, 0, 1, 1, 1, 1], ("tensor.nonMaximumSuppression", {"box": CORNERS, "scoreIndex": 1, "scoreActivation": "sigmoid"}))

        self.assertAlmostEqual(result["score"], 0.5, places=6)

    def test_rejects_softmax_on_a_single_column_and_a_class_column_with_class_scores(self):
        with self.assertRaisesRegex(ValueError, "softmax braucht classScores"):
            run(self.rows, ("tensor.nonMaximumSuppression", {"box": CORNERS, "scoreIndex": 1, "scoreActivation": "softmax"}))
        with self.assertRaisesRegex(ValueError, "classColumn passt nur zu scoreIndex"):
            run(self.rows, ("tensor.nonMaximumSuppression", {"box": CORNERS, "classScores": {"start": 1, "end": 2}, "classColumn": 0}))


if __name__ == "__main__":
    unittest.main()
