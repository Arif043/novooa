import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import base64
import importlib.util

import numpy

from ml_test_support import decoded_tensor, run
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.model_output.worker import transform_outputs
from novooa_ml.tensor_codec import decode_tensor, encode_tensor

FIXTURES = Path(__file__).resolve().parent / "fixtures" / "sklearn"
HAS_ONNXRUNTIME = importlib.util.find_spec("onnxruntime") is not None


class TensorCodecTest(unittest.TestCase):
    def test_round_trips_string_tensors_in_row_order(self):
        values = numpy.array([["DE", "Grüße"], ["AT", ""]], dtype=object)

        encoded = encode_tensor("land", values, numpy)
        decoded = decode_tensor(encoded, numpy)

        self.assertEqual((encoded["dataType"], encoded["shape"]), ("string", [2, 2]))
        self.assertEqual(decoded.dtype, object)
        self.assertEqual(decoded.tolist(), [["DE", "Grüße"], ["AT", ""]])

    def test_encodes_numpy_unicode_and_byte_strings_as_text(self):
        self.assertEqual(decode_tensor(encode_tensor("a", numpy.array(["x", "y"]), numpy), numpy).tolist(), ["x", "y"])
        self.assertEqual(decode_tensor(encode_tensor("b", numpy.array([b"z"]), numpy), numpy).tolist(), ["z"])

    def test_round_trips_float16(self):
        values = numpy.array([0.5, -2.0, 1024.0], dtype=numpy.float16)

        encoded = encode_tensor("x", values, numpy)

        self.assertEqual((encoded["dataType"], len(base64.b64decode(encoded["dataBase64"]))), ("float16", 6))
        numpy.testing.assert_array_equal(decode_tensor(encoded, numpy), values)

    def test_rejects_unknown_types_and_mismatching_string_counts(self):
        with self.assertRaisesRegex(ValueError, "Nicht unterstützter Tensor-Datentyp: complex64"):
            encode_tensor("x", numpy.zeros(1, dtype=numpy.complex64), numpy)
        broken = {"name": "x", "dataType": "string", "shape": [3], "dataBase64": base64.b64encode(b'["a"]').decode()}
        with self.assertRaisesRegex(ValueError, "String-Tensor x"):
            decode_tensor(broken, numpy)


class ZipMapOutputTest(unittest.TestCase):
    definitions = [{"name": "output_probability", "transformations": []}]

    def test_turns_a_list_of_class_maps_into_a_dense_tensor_with_classes(self):
        [output] = transform_outputs(
            [("output_probability", [{"ja": 0.9, "nein": 0.1}, {"ja": 0.2, "nein": 0.8}])], self.definitions, numpy,
        )

        self.assertEqual(output["tensor"].dtype, numpy.float32)
        numpy.testing.assert_allclose(output["tensor"], [[0.9, 0.1], [0.2, 0.8]])
        self.assertEqual(output["transformationValues"]["classes"], ["ja", "nein"])

    def test_keeps_numeric_class_keys(self):
        [output] = transform_outputs([("output_probability", [{0: 0.3, 1: 0.7}])], self.definitions, numpy)

        self.assertEqual(output["transformationValues"]["classes"], [0, 1])

    def test_rejects_rows_with_different_classes(self):
        with self.assertRaisesRegex(ValueError, "output_probability: Die Klassen der Einträge unterscheiden sich"):
            transform_outputs([("output_probability", [{"ja": 1.0}, {"nein": 1.0}])], self.definitions, numpy)


class StringInputTest(unittest.TestCase):
    def test_text_becomes_a_single_string_tensor(self):
        result = run("Hallo Welt", ("text.toTensor", {}))

        self.assertEqual((result.dtype, result.shape, result.tolist()), (object, (1,), ["Hallo Welt"]))

    def test_json_string_tables_become_string_tensors(self):
        result = run([["DE"], ["AT"]], ("json.toTensor", {}))

        self.assertEqual((result.dtype, result.shape), (object, (2, 1)))

    def test_json_rejects_mixed_strings_and_numbers(self):
        with self.assertRaisesRegex(ValueError, "json.toTensor"):
            run(["DE", 1], ("json.toTensor", {}))

    def test_string_tensors_reach_the_model_through_the_input_worker(self):
        payload = {
            "input": {"name": "land", "dataType": "string", "shape": ["dynamic", 1],
                      "transformations": [{"type": "json.toTensor", "parameters": {}}]},
            "source": {"type": "json", "value": [["AT"]]},
        }

        encoded = transform_payload(payload)["tensor"]

        self.assertEqual((encoded["dataType"], encoded["shape"]), ("string", [1, 1]))
        self.assertEqual(decode_tensor(encoded, numpy).tolist(), [["AT"]])


@unittest.skipUnless(HAS_ONNXRUNTIME, "onnxruntime fehlt")
class SklearnModelTest(unittest.TestCase):
    """Echte scikit-learn-Modelle (siehe fixtures/sklearn/build_fixtures.py), geladen per Pfad wie im ML-Dienst."""

    def execute(self, fixture, inputs, outputs):
        import onnxruntime

        from novooa_ml.model_execution import run_model, session_factory

        session = session_factory(onnxruntime)(str(FIXTURES / f"{fixture}.onnx"))
        payload = {"inputs": inputs, "outputs": outputs}
        return {output["name"]: output for output in run_model(session, payload, numpy)}

    def test_classifier_with_text_classes_and_zipmap(self):
        outputs = self.execute(
            "classifier_text_classes",
            [encode_tensor("X", numpy.array([[3, 3]], dtype=numpy.float32), numpy)],
            [
                {"name": "output_label", "transformations": []},
                {"name": "output_probability", "transformations": [
                    {"type": "tensor.reduce", "parameters": {"operation": "max"}, "result": "best"},
                ]},
            ],
        )

        label, probability = outputs["output_label"], outputs["output_probability"]
        self.assertEqual((label["dataType"], label["transformationValues"]["tensor"]), ("string", ["ja"]))
        self.assertEqual((probability["dataType"], probability["shape"]), ("float32", [1, 2]))
        self.assertEqual(probability["transformationValues"]["classes"], ["ja", "nein"])
        self.assertGreater(probability["transformationValues"]["best"][0], 0.9)

    def test_regressor(self):
        outputs = self.execute(
            "regressor", [encode_tensor("X", numpy.array([[1, 1]], dtype=numpy.float32), numpy)],
            [{"name": "variable", "transformations": []}],
        )

        numpy.testing.assert_allclose(outputs["variable"]["transformationValues"]["tensor"], [[6.0]], rtol=1e-5)

    def test_pipeline_with_a_text_column_from_a_workflow_record(self):
        def model_input(name, data_type, steps, value):
            return transform_payload({
                "input": {"name": name, "dataType": data_type, "shape": ["dynamic", 1], "transformations": steps},
                "source": {"type": "json", "value": value},
            })["tensor"]

        record = {"land": "CH", "umsatz": 88}
        outputs = self.execute(
            "pipeline_text_column",
            [
                model_input("land", "string", [{"type": "json.toTensor", "parameters": {}}], [[record["land"]]]),
                model_input("umsatz", "float32", [{"type": "json.features", "parameters": {"features": [{"field": "umsatz"}]}}], [record]),
            ],
            [{"name": "label", "transformations": []}, {"name": "probabilities", "transformations": []}],
        )

        self.assertEqual(outputs["label"]["transformationValues"]["tensor"], [1])
        self.assertEqual(outputs["probabilities"]["shape"], [1, 2])


if __name__ == "__main__":
    unittest.main()
