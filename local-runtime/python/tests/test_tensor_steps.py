import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy
from PIL import Image

from ml_test_support import context, run


class SoftmaxTest(unittest.TestCase):
    def test_turns_each_row_into_probabilities(self):
        result = run(numpy.array([[1.0, 2.0, 3.0], [0.0, 0.0, 0.0]]), ("tensor.softmax", {}))

        numpy.testing.assert_allclose(result.sum(axis=-1), [1, 1])
        numpy.testing.assert_allclose(result[1], [1 / 3] * 3)
        self.assertTrue(numpy.all(numpy.diff(result[0]) > 0))

    def test_stays_stable_for_large_logits(self):
        result = run(numpy.array([1000.0, 1001.0]), ("tensor.softmax", {}))

        self.assertTrue(numpy.all(numpy.isfinite(result)))
        numpy.testing.assert_allclose(result, [0.26894142, 0.73105858], rtol=1e-6)

    def test_supports_only_the_last_axis(self):
        with self.assertRaisesRegex(ValueError, "nur die letzte Tensorachse"):
            run(numpy.zeros((2, 2)), ("tensor.softmax", {"axis": 0}))


class SigmoidTest(unittest.TestCase):
    def test_maps_logits_into_probabilities(self):
        result = run(numpy.array([-100.0, 0.0, 2.0]), ("tensor.sigmoid", {}))

        numpy.testing.assert_allclose(result, [0.0, 0.5, 0.88079708], atol=1e-6)


class ThresholdTest(unittest.TestCase):
    def test_uses_half_as_default_and_includes_the_boundary(self):
        result = run(numpy.array([0.2, 0.5, 0.9]), ("tensor.threshold", {}))

        self.assertEqual(result.tolist(), [False, True, True])

    def test_accepts_a_custom_value(self):
        self.assertEqual(run(numpy.array([0.2, 0.5]), ("tensor.threshold", {"value": 0.1})).tolist(), [True, True])

    def test_rejects_a_non_numeric_value(self):
        with self.assertRaisesRegex(ValueError, "numerischen Wert"):
            run(numpy.array([0.2]), ("tensor.threshold", {"value": "hoch"}))


class TopKTest(unittest.TestCase):
    def test_returns_the_largest_values_in_descending_order(self):
        result = run(numpy.array([[0.1, 0.6, 0.3]]), ("tensor.topK", {"k": 2}))

        self.assertEqual(result, [{"index": 1, "value": 0.6}, {"index": 2, "value": 0.3}])

    def test_returns_all_values_when_k_exceeds_the_vector(self):
        self.assertEqual(len(run(numpy.array([0.4, 0.6]), ("tensor.topK", {"k": 5}))), 2)

    def test_old_parameter_descriptions_fall_back_to_their_default(self):
        legacy = {"parameter": {"name": "k", "default": 1, "minimum": 1, "maximum": 5}}

        self.assertEqual(len(run(numpy.array([0.4, 0.6, 0.1]), ("tensor.topK", legacy))), 1)

    def test_rejects_batches_and_invalid_counts(self):
        with self.assertRaisesRegex(ValueError, "nur einzelne Vektoren"):
            run(numpy.zeros((2, 3)), ("tensor.topK", {"k": 1}))
        for count in [None, 0, 1.5, True, "3"]:
            with self.subTest(count=count), self.assertRaisesRegex(ValueError, "tensor.topK benötigt k als positive ganze Zahl"):
                run(numpy.zeros(3), ("tensor.topK", {} if count is None else {"k": count}))


class LayoutAndNormalizeTest(unittest.TestCase):
    def image_tensor(self):
        return numpy.stack([numpy.full((2, 2), value, dtype=numpy.float32) for value in (10, 20, 30)], axis=-1)

    def test_switches_between_channels_last_and_channels_first(self):
        first = run(self.image_tensor(), ("tensor.layout", {"order": "channelsFirst"}))
        back = run(self.image_tensor(), ("tensor.layout", {"order": "channelsFirst"}), ("tensor.layout", {"order": "channelsLast"}))

        self.assertEqual(first.shape, (3, 2, 2))
        numpy.testing.assert_array_equal(back, self.image_tensor())

    def test_keeps_a_tensor_already_in_the_requested_layout(self):
        tensor = self.image_tensor()

        self.assertIs(run(tensor, ("tensor.layout", {"order": "channelsLast"})), tensor)

    def test_normalizes_each_channel_in_either_layout(self):
        parameters = {"mean": [10, 20, 30], "std": [1, 2, 5]}
        last = run(self.image_tensor(), ("tensor.normalize", parameters))
        first = run(self.image_tensor(), ("tensor.layout", {"order": "channelsFirst"}), ("tensor.normalize", parameters))

        numpy.testing.assert_allclose(last, 0)
        numpy.testing.assert_allclose(first, 0)

    def test_normalize_rejects_mismatched_channels_and_zero_deviation(self):
        with self.assertRaisesRegex(ValueError, "jeden Farbkanal"):
            run(self.image_tensor(), ("tensor.normalize", {"mean": [0, 0], "std": [1, 1]}))
        with self.assertRaisesRegex(ValueError, "Standardabweichung von null"):
            run(self.image_tensor(), ("tensor.normalize", {"mean": [0, 0, 0], "std": [1, 0, 1]}))

    def test_layout_rejects_an_unknown_order(self):
        with self.assertRaisesRegex(ValueError, "channelsFirst oder channelsLast"):
            run(self.image_tensor(), ("tensor.layout", {"order": "HWC"}))

    def test_reads_images_directly_as_tensors(self):
        tensor = run(Image.new("RGB", (4, 2), (1, 2, 3)), ("tensor.layout", {"order": "channelsFirst"}))

        self.assertEqual(tensor.shape, (3, 2, 4))
        self.assertEqual(tensor[:, 0, 0].tolist(), [1, 2, 3])


class ConstantTest(unittest.TestCase):
    def test_replaces_any_value_with_the_declared_numbers(self):
        result = run("beliebig", ("tensor.constant", {"values": [1, 2.5]}))

        self.assertEqual((result.dtype, result.tolist()), (numpy.float32, [1.0, 2.5]))

    def test_rejects_empty_or_non_numeric_values(self):
        for values in [[], ["a"], None]:
            with self.subTest(values=values), self.assertRaisesRegex(ValueError, "nicht leeres Zahlenfeld"):
                run("x", ("tensor.constant", {"values": values}))



class MinMaxScaleTest(unittest.TestCase):
    def test_maps_the_own_range_onto_the_target_range(self):
        result = run(numpy.array([[2.0, 4.0], [6.0, 10.0]]), ("tensor.minMaxScale", {"maximum": 255}))

        numpy.testing.assert_allclose(result, [[0, 63.75], [127.5, 255]])

    def test_a_constant_tensor_becomes_the_minimum(self):
        result = run(numpy.full((2, 2), 3.0), ("tensor.minMaxScale", {"minimum": 1, "maximum": 2}))

        numpy.testing.assert_allclose(result, numpy.ones((2, 2)))

    def test_rejects_an_empty_target_range(self):
        with self.assertRaisesRegex(ValueError, "maximum größer als minimum"):
            run(numpy.zeros(2), ("tensor.minMaxScale", {"minimum": 1, "maximum": 1}))


class BatchLayoutTest(unittest.TestCase):
    """Kacheln aus `image.tiles` werden je Bild umgeordnet und normalisiert."""

    def test_reorders_and_normalizes_every_image_of_a_batch(self):
        batch = numpy.zeros((2, 3, 4, 3), dtype=numpy.float32)
        batch[1, ..., 2] = 10.0
        ctx = context()

        result = run(batch, ("tensor.layout", {"order": "channelsFirst"}),
                     ("tensor.normalize", {"mean": [0, 0, 5], "std": [1, 1, 5]}), ctx=ctx)

        self.assertEqual(result.shape, (2, 3, 3, 4))
        numpy.testing.assert_allclose(result[1, 2], numpy.ones((3, 4)))
        numpy.testing.assert_allclose(result[0, 2], -numpy.ones((3, 4)))

    def test_rejects_a_tensor_that_is_neither_image_nor_batch(self):
        with self.assertRaisesRegex(ValueError, "Batch \\[N, H, W, C\\]"):
            run(numpy.zeros((2, 2)), ("tensor.layout", {"order": "channelsFirst"}))


if __name__ == "__main__":
    unittest.main()
