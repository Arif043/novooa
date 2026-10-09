import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy

from novooa_ml.output_transforms.default_registry import default_output_transformation_registry
from novooa_ml.transformations.context import TransformationContext
from novooa_ml.output_transforms.worker import transformation_values


def process(tensor, *transformations):
    return transformation_values(default_output_transformation_registry(), 
        numpy.asarray(tensor),
        [{"type": kind, "parameters": parameters, "result": "value"} for kind, parameters in transformations],
        TransformationContext(numpy, output_name="output", output_parameters=[]),
    )["value"]


class ArgmaxTest(unittest.TestCase):
    def test_returns_the_index_of_the_largest_value_per_row(self):
        self.assertEqual(process([[0.1, 0.7, 0.2], [0.9, 0.0, 0.1]], ("tensor.argmax", {})), [1, 0])

    def test_reduces_another_axis(self):
        self.assertEqual(process([[1, 5], [4, 2]], ("tensor.argmax", {"axis": 0})), [1, 0])

    def test_rejects_an_axis_outside_the_tensor(self):
        with self.assertRaisesRegex(ValueError, "Achse"):
            process([1, 2], ("tensor.argmax", {"axis": 3}))


class SqueezeTest(unittest.TestCase):
    def test_removes_dimensions_of_size_one(self):
        self.assertEqual(process([[[1], [2]]], ("tensor.squeeze", {})), [1, 2])


class ReduceTest(unittest.TestCase):
    def test_supports_mean_sum_max_and_min(self):
        tensor = [[1, 2, 3], [4, 5, 6]]
        expectations = {"mean": [2.0, 5.0], "sum": [6, 15], "max": [3, 6], "min": [1, 4]}
        for operation, expected in expectations.items():
            with self.subTest(operation=operation):
                self.assertEqual(process(tensor, ("tensor.reduce", {"operation": operation})), expected)

    def test_pools_token_embeddings_over_the_sequence_axis(self):
        tokens = [[[1.0, 0.0], [3.0, 2.0]]]

        self.assertEqual(process(tokens, ("tensor.reduce", {"operation": "mean", "axis": 1})), [[2.0, 1.0]])

    def test_rejects_an_unknown_operation(self):
        with self.assertRaisesRegex(ValueError, "mean, sum, max oder min"):
            process([1, 2], ("tensor.reduce", {"operation": "median"}))


class L2NormalizeTest(unittest.TestCase):
    def test_scales_vectors_to_unit_length(self):
        result = process([[3.0, 4.0], [0.0, 2.0]], ("tensor.l2Normalize", {}))

        numpy.testing.assert_allclose(result, [[0.6, 0.8], [0.0, 1.0]])

    def test_leaves_zero_vectors_unchanged(self):
        self.assertEqual(process([0.0, 0.0], ("tensor.l2Normalize", {})), [0.0, 0.0])


class SliceTest(unittest.TestCase):
    def test_selects_a_range_along_an_axis(self):
        tensor = [[0, 1, 2, 3], [4, 5, 6, 7]]

        self.assertEqual(process(tensor, ("tensor.slice", {"axis": 1, "start": 1, "end": 3})), [[1, 2], [5, 6]])
        self.assertEqual(process(tensor, ("tensor.slice", {"start": -1})), [[3], [7]])

    def test_rejects_invalid_bounds(self):
        with self.assertRaisesRegex(ValueError, "start"):
            process([1, 2], ("tensor.slice", {}))
        with self.assertRaisesRegex(ValueError, "leer"):
            process([1, 2, 3], ("tensor.slice", {"start": 2, "end": 1}))


class RoundTest(unittest.TestCase):
    def test_rounds_to_the_given_decimals(self):
        self.assertEqual(process([1.2345, 2.5], ("tensor.round", {"decimals": 2})), [1.23, 2.5])
        self.assertEqual(process([1.6], ("tensor.round", {})), [2.0])

    def test_rejects_negative_decimals(self):
        with self.assertRaisesRegex(ValueError, "decimals"):
            process([1.0], ("tensor.round", {"decimals": -1}))


class SharedTensorOperationsTest(unittest.TestCase):
    def test_denormalizes_and_reshapes_a_regression_output(self):
        result = process(
            [[0.5, 1.0, 0.0, 0.25]],
            ("tensor.scale", {"factor": 100, "offset": 10}),
            ("tensor.clip", {"max": 100}),
            ("tensor.reshape", {"shape": [2, 2]}),
            ("tensor.transpose", {"axes": [1, 0]}),
        )

        self.assertEqual(result, [[60.0, 10.0], [100.0, 35.0]])

    def test_chains_into_existing_transformations(self):
        result = process([[2.0, 1.0, 0.1]], ("tensor.softmax", {}), ("tensor.argmax", {}))

        self.assertEqual(result, [0])


if __name__ == "__main__":
    unittest.main()
