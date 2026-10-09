import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy

from novooa_ml.transformations.parameters import axis_of
from novooa_ml.transformations.tensor.clip import clip
from novooa_ml.transformations.tensor.fit_length import fit_length
from novooa_ml.transformations.tensor.reshape import reshape
from novooa_ml.transformations.tensor.scale import scale
from novooa_ml.transformations.tensor.transpose import transpose


class ScaleTest(unittest.TestCase):
    def test_multiplies_and_adds_an_offset(self):
        result = scale(numpy, numpy.array([0, 255]), {"factor": 1 / 255, "offset": -0.5})

        numpy.testing.assert_allclose(result, [-0.5, 0.5])
        self.assertEqual(result.dtype, numpy.float32)

    def test_defaults_keep_the_values(self):
        numpy.testing.assert_allclose(scale(numpy, numpy.array([2, 3]), {}), [2, 3])

    def test_rejects_non_numeric_parameters(self):
        with self.assertRaisesRegex(ValueError, "tensor.scale"):
            scale(numpy, numpy.array([1]), {"factor": "2"})


class ClipTest(unittest.TestCase):
    def test_limits_values_to_the_range(self):
        result = clip(numpy, numpy.array([-2.0, 0.5, 3.0]), {"min": 0, "max": 1})

        numpy.testing.assert_allclose(result, [0, 0.5, 1])

    def test_accepts_a_single_bound(self):
        numpy.testing.assert_allclose(clip(numpy, numpy.array([-1, 5]), {"min": 0}), [0, 5])

    def test_requires_a_bound_and_a_valid_range(self):
        with self.assertRaisesRegex(ValueError, "min oder max"):
            clip(numpy, numpy.array([1]), {})
        with self.assertRaisesRegex(ValueError, "min darf nicht größer"):
            clip(numpy, numpy.array([1]), {"min": 2, "max": 1})


class ReshapeTest(unittest.TestCase):
    def test_reshapes_and_infers_one_dimension(self):
        result = reshape(numpy, numpy.arange(6), {"shape": [2, -1]})

        self.assertEqual(result.shape, (2, 3))

    def test_rejects_an_incompatible_or_ambiguous_shape(self):
        with self.assertRaisesRegex(ValueError, "passt nicht"):
            reshape(numpy, numpy.arange(6), {"shape": [4, -1]})
        with self.assertRaisesRegex(ValueError, "höchstens eine"):
            reshape(numpy, numpy.arange(6), {"shape": [-1, -1]})
        with self.assertRaisesRegex(ValueError, "shape"):
            reshape(numpy, numpy.arange(6), {"shape": [2, 0]})


class TransposeTest(unittest.TestCase):
    def test_reorders_the_axes(self):
        result = transpose(numpy, numpy.zeros((2, 3, 4)), {"axes": [2, 0, 1]})

        self.assertEqual(result.shape, (4, 2, 3))

    def test_requires_a_complete_permutation(self):
        with self.assertRaisesRegex(ValueError, "Permutation"):
            transpose(numpy, numpy.zeros((2, 3)), {"axes": [0, 0]})
        with self.assertRaisesRegex(ValueError, "Permutation"):
            transpose(numpy, numpy.zeros((2, 3)), {"axes": [1]})


class AxisTest(unittest.TestCase):
    def test_accepts_negative_axes_within_the_tensor(self):
        self.assertEqual(axis_of(numpy.zeros((2, 3)), {"axis": -1}, "tensor.test"), -1)
        self.assertEqual(axis_of(numpy.zeros((2, 3)), {}, "tensor.test"), -1)

    def test_rejects_axes_outside_the_tensor(self):
        with self.assertRaisesRegex(ValueError, "tensor.test.*Achse"):
            axis_of(numpy.zeros((2, 3)), {"axis": 2}, "tensor.test")
        with self.assertRaisesRegex(ValueError, "Achse"):
            axis_of(numpy.zeros((2, 3)), {"axis": 1.5}, "tensor.test")


if __name__ == "__main__":
    unittest.main()
