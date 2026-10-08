import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy

from novooa_ml import tensor_operations as operations


class ScaleTest(unittest.TestCase):
    def test_multiplies_and_adds_an_offset(self):
        result = operations.scale(numpy, numpy.array([0, 255]), {"factor": 1 / 255, "offset": -0.5})

        numpy.testing.assert_allclose(result, [-0.5, 0.5])
        self.assertEqual(result.dtype, numpy.float32)

    def test_defaults_keep_the_values(self):
        numpy.testing.assert_allclose(operations.scale(numpy, numpy.array([2, 3]), {}), [2, 3])

    def test_rejects_non_numeric_parameters(self):
        with self.assertRaisesRegex(ValueError, "tensor.scale"):
            operations.scale(numpy, numpy.array([1]), {"factor": "2"})


class ClipTest(unittest.TestCase):
    def test_limits_values_to_the_range(self):
        result = operations.clip(numpy, numpy.array([-2.0, 0.5, 3.0]), {"min": 0, "max": 1})

        numpy.testing.assert_allclose(result, [0, 0.5, 1])

    def test_accepts_a_single_bound(self):
        numpy.testing.assert_allclose(operations.clip(numpy, numpy.array([-1, 5]), {"min": 0}), [0, 5])

    def test_requires_a_bound_and_a_valid_range(self):
        with self.assertRaisesRegex(ValueError, "min oder max"):
            operations.clip(numpy, numpy.array([1]), {})
        with self.assertRaisesRegex(ValueError, "min darf nicht größer"):
            operations.clip(numpy, numpy.array([1]), {"min": 2, "max": 1})


class ReshapeTest(unittest.TestCase):
    def test_reshapes_and_infers_one_dimension(self):
        result = operations.reshape(numpy, numpy.arange(6), {"shape": [2, -1]})

        self.assertEqual(result.shape, (2, 3))

    def test_rejects_an_incompatible_or_ambiguous_shape(self):
        with self.assertRaisesRegex(ValueError, "passt nicht"):
            operations.reshape(numpy, numpy.arange(6), {"shape": [4, -1]})
        with self.assertRaisesRegex(ValueError, "höchstens eine"):
            operations.reshape(numpy, numpy.arange(6), {"shape": [-1, -1]})
        with self.assertRaisesRegex(ValueError, "shape"):
            operations.reshape(numpy, numpy.arange(6), {"shape": [2, 0]})


class TransposeTest(unittest.TestCase):
    def test_reorders_the_axes(self):
        result = operations.transpose(numpy, numpy.zeros((2, 3, 4)), {"axes": [2, 0, 1]})

        self.assertEqual(result.shape, (4, 2, 3))

    def test_requires_a_complete_permutation(self):
        with self.assertRaisesRegex(ValueError, "Permutation"):
            operations.transpose(numpy, numpy.zeros((2, 3)), {"axes": [0, 0]})
        with self.assertRaisesRegex(ValueError, "Permutation"):
            operations.transpose(numpy, numpy.zeros((2, 3)), {"axes": [1]})


class AxisTest(unittest.TestCase):
    def test_accepts_negative_axes_within_the_tensor(self):
        self.assertEqual(operations.axis_of(numpy.zeros((2, 3)), {"axis": -1}, "tensor.test"), -1)
        self.assertEqual(operations.axis_of(numpy.zeros((2, 3)), {}, "tensor.test"), -1)

    def test_rejects_axes_outside_the_tensor(self):
        with self.assertRaisesRegex(ValueError, "tensor.test.*Achse"):
            operations.axis_of(numpy.zeros((2, 3)), {"axis": 2}, "tensor.test")
        with self.assertRaisesRegex(ValueError, "Achse"):
            operations.axis_of(numpy.zeros((2, 3)), {"axis": 1.5}, "tensor.test")


if __name__ == "__main__":
    unittest.main()
