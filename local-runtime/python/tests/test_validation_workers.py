import json
import subprocess
import sys
import unittest
from pathlib import Path

PYTHON_ROOT = Path(__file__).resolve().parents[1]
FIXTURES = Path(__file__).resolve().parent / "fixtures" / "sklearn"


def run_worker(script, payload):
    # Wie die Runtime: isoliert (`-I`), Nutzlast über stdin.
    return subprocess.run(
        [sys.executable, "-I", str(PYTHON_ROOT / script)],
        input=json.dumps(payload), capture_output=True, text=True, check=False,
    )


def tensor(name, data_type, shape):
    return {"name": name, "dataType": data_type, "shape": shape}


class OnnxValidationWorkerTest(unittest.TestCase):
    def validate(self, model, inputs, outputs):
        contract = {"inputs": inputs, "outputs": outputs}
        return run_worker("onnx_validation_worker.py", {"artifactPath": str(FIXTURES / model), "contract": contract})

    def test_accepts_string_tensors_and_zipmap_outputs(self):
        completed = self.validate(
            "classifier_text_classes.onnx",
            [tensor("X", "float32", ["dynamic", 2])],
            [tensor("output_label", "string", ["dynamic"]),
             tensor("output_probability", "float32", ["dynamic", "dynamic"])],
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(json.loads(completed.stdout), {"valid": True})

    def test_accepts_a_fixed_size_where_the_model_axis_is_dynamic(self):
        completed = self.validate(
            "pipeline_text_column.onnx",
            [tensor("land", "string", [1, 1]), tensor("umsatz", "float32", [1, 1])],
            [tensor("probabilities", "float32", [1, 2])],
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)

    def test_rejects_a_wrong_data_type_with_both_types(self):
        completed = self.validate(
            "regressor.onnx",
            [tensor("X", "float16", ["dynamic", 2])],
            [tensor("variable", "float32", ["dynamic", 1])],
        )

        self.assertEqual(completed.returncode, 1)
        self.assertIn("Vertrag float16, Modell tensor(float)", completed.stderr)

    def test_rejects_a_wrong_fixed_dimension(self):
        completed = self.validate(
            "regressor.onnx",
            [tensor("X", "float32", ["dynamic", 3])],
            [tensor("variable", "float32", ["dynamic", 1])],
        )

        self.assertEqual(completed.returncode, 1)
        self.assertIn("Tensor-Form von X", completed.stderr)


class ContractValidationWorkerTest(unittest.TestCase):
    def test_accepts_a_valid_contract(self):
        contract = {"inputs": [{"name": "bild", "source": "image", "transformations": [
            {"type": "image.resizeShorterSide", "parameters": {"size": 256}},
        ]}], "outputs": []}

        completed = run_worker("contract_validation_worker.py", {"contract": contract})

        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertEqual(json.loads(completed.stdout), {"status": "ok"})

    def test_names_a_misspelled_parameter(self):
        contract = {"inputs": [{"name": "bild", "source": "image", "transformations": [
            {"type": "image.resize", "parameters": {"width": 224, "hieght": 224}},
        ]}], "outputs": []}

        completed = run_worker("contract_validation_worker.py", {"contract": contract})

        self.assertEqual(completed.returncode, 1)
        self.assertIn("Eingang bild: image.resize", completed.stderr)


if __name__ == "__main__":
    unittest.main()
