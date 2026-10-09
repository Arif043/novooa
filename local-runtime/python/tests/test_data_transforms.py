import base64
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy

from novooa_ml import tensor_operations as operations
from novooa_ml.input_transforms.worker import transform_payload


def tensor_of(source_type, value, transformations, shape=None):
    payload = {
        "input": {
            "name": "input", "dataType": "float32", "shape": shape or ["dynamic"],
            "transformations": [{"type": kind, "parameters": parameters} for kind, parameters in transformations],
        },
        "source": {"type": source_type, "value": value},
    }
    result = transform_payload(payload)["tensor"]
    values = numpy.frombuffer(base64.b64decode(result["dataBase64"]), dtype=numpy.float32)
    return values.reshape(result["shape"])


class JsonToTensorTest(unittest.TestCase):
    def test_converts_nested_number_lists(self):
        tensor = tensor_of("json", [[1, 2], [3, 4.5]], [("json.toTensor", {})], ["dynamic", 2])

        numpy.testing.assert_allclose(tensor, [[1, 2], [3, 4.5]])

    def test_converts_booleans_and_single_values(self):
        numpy.testing.assert_allclose(tensor_of("json", [True, False], [("json.toTensor", {})]), [1, 0])
        numpy.testing.assert_allclose(tensor_of("boolean", True, [("json.toTensor", {})]), [1])
        numpy.testing.assert_allclose(tensor_of("json", 7, [("json.toTensor", {})]), [7])

    def test_rejects_ragged_or_non_numeric_values(self):
        for value in [[[1, 2], [3]], ["a"], {"a": 1}, None, []]:
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "json.toTensor"):
                tensor_of("json", value, [("json.toTensor", {})])


class JsonFeaturesTest(unittest.TestCase):
    features = [
        {"field": "alter", "mean": 40, "std": 10},
        {"field": "kunde.premium", "kind": "boolean"},
        {"field": "land", "kind": "category", "categories": ["DE", "AT", "CH"]},
        {"field": "umsatz", "default": 0},
    ]

    def test_builds_a_feature_vector_in_the_declared_order(self):
        record = {"alter": 50, "kunde": {"premium": True}, "land": "AT", "umsatz": 120.5}

        tensor = tensor_of("json", record, [("json.features", {"features": self.features})])

        numpy.testing.assert_allclose(tensor, [1.0, 1.0, 0, 1, 0, 120.5])

    def test_builds_one_row_per_record_and_uses_defaults(self):
        records = [
            {"alter": 40, "kunde": {"premium": False}, "land": "DE"},
            {"alter": 30, "kunde": {"premium": True}, "land": "CH", "umsatz": 5},
        ]

        tensor = tensor_of("json", records, [("json.features", {"features": self.features})], ["dynamic", 6])

        numpy.testing.assert_allclose(tensor, [[0, 0, 1, 0, 0, 0], [-1, 1, 0, 0, 1, 5]])

    def test_unknown_categories_become_all_zero_unless_forbidden(self):
        record = {"alter": 40, "kunde": {"premium": False}, "land": "FR"}

        tensor = tensor_of("json", record, [("json.features", {"features": self.features})])

        numpy.testing.assert_allclose(tensor[2:5], [0, 0, 0])
        strict = [{"field": "land", "kind": "category", "categories": ["DE"], "unknown": "error"}]
        with self.assertRaisesRegex(ValueError, "land.*FR"):
            tensor_of("json", record, [("json.features", {"features": strict})])

    def test_reports_missing_fields_and_wrong_types(self):
        with self.assertRaisesRegex(ValueError, "alter.*fehlt"):
            tensor_of("json", {"land": "DE"}, [("json.features", {"features": [{"field": "alter"}]})])
        with self.assertRaisesRegex(ValueError, "alter.*keine Zahl"):
            tensor_of("json", {"alter": "alt"}, [("json.features", {"features": [{"field": "alter"}]})])
        with self.assertRaisesRegex(ValueError, "features"):
            tensor_of("json", {"alter": 1}, [("json.features", {"features": []})])
        with self.assertRaisesRegex(ValueError, "std"):
            tensor_of("json", {"alter": 1}, [("json.features", {"features": [{"field": "alter", "std": 0}]})])


class FitLengthTest(unittest.TestCase):
    def test_pads_with_a_value_at_the_end(self):
        result = operations.fit_length(numpy, numpy.array([1, 2]), {"length": 4, "value": -1})

        numpy.testing.assert_allclose(result, [1, 2, -1, -1])

    def test_keeps_the_most_recent_values_for_time_series(self):
        result = operations.fit_length(numpy, numpy.arange(10), {"length": 3, "keep": "end"})

        numpy.testing.assert_allclose(result, [7, 8, 9])

    def test_pads_in_front_when_keeping_the_end(self):
        result = operations.fit_length(numpy, numpy.array([5, 6]), {"length": 4, "keep": "end"})

        numpy.testing.assert_allclose(result, [0, 0, 5, 6])

    def test_works_along_another_axis(self):
        result = operations.fit_length(numpy, numpy.ones((2, 3)), {"length": 4, "axis": 0})

        self.assertEqual(result.shape, (4, 3))
        numpy.testing.assert_allclose(result[2:], 0)

    def test_rejects_invalid_parameters(self):
        with self.assertRaisesRegex(ValueError, "length"):
            operations.fit_length(numpy, numpy.ones(3), {"length": 0})
        with self.assertRaisesRegex(ValueError, "keep"):
            operations.fit_length(numpy, numpy.ones(3), {"length": 2, "keep": "middle"})

    def test_builds_a_time_series_window_from_a_number_list(self):
        tensor = tensor_of("number", [1, 2, 3, 4, 5], [("number.toTensor", {}), ("tensor.fitLength", {"length": 3, "keep": "end"})])

        numpy.testing.assert_allclose(tensor, [3, 4, 5])


class UnsupportedSourceTest(unittest.TestCase):
    def test_names_the_source_type_that_is_not_supported(self):
        with self.assertRaisesRegex(ValueError, "datetime"):
            tensor_of("datetime", "2026-10-08T10:00:00Z", [])


if __name__ == "__main__":
    unittest.main()
