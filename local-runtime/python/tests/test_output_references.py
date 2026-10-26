import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy

from ml_test_support import REGISTRY, context, run
from novooa_ml.model_execution import run_model
from novooa_ml.tensor_codec import encode_tensor
from novooa_ml.transformations.output_references import referenced_outputs

PYTHON_ROOT = Path(__file__).resolve().parents[1]
FIXTURES = Path(__file__).resolve().parent / "fixtures" / "sklearn"
DETR_LIKE = Path(__file__).resolve().parent / "fixtures" / "detectors" / "detr_like.onnx"


class Output:
    def __init__(self, name):
        self.name = name


class DetrLikeSession:
    """Zwei Ausgänge wie RT-DETR/D-FINE: normierte Boxen `[1, 3, 4]` und Klassen-Logits `[1, 3, 2]`."""

    boxes = numpy.array([[[0.5, 0.5, 0.2, 0.4], [0.25, 0.25, 0.1, 0.1], [0.8, 0.2, 0.2, 0.2]]], dtype=numpy.float32)
    logits = numpy.array([[[2.0, -1.0], [-3.0, -2.5], [-1.0, 1.5]]], dtype=numpy.float32)

    def get_outputs(self):
        return [Output("pred_boxes"), Output("logits")]

    def run(self, names, inputs):
        values = {"pred_boxes": self.boxes, "logits": self.logits}
        return [values[name] for name in names]


def detr_payload():
    pipeline = [
        {"type": "tensor.concat", "parameters": {"outputs": ["logits"]}},
        {"type": "tensor.squeeze", "parameters": {}},
        {"type": "tensor.nonMaximumSuppression", "result": "objects", "parameters": {
            "box": {"centerX": 0, "centerY": 1, "width": 2, "height": 3}, "classScores": {"start": 4},
            "scoreActivation": "sigmoid", "suppress": False, "boxScale": {"x": 640, "y": 480},
            "scoreThreshold": 0.5,
        }},
    ]
    image = encode_tensor("images", numpy.zeros((1, 3, 4, 4), dtype=numpy.float32), numpy)
    return {"inputs": [image], "outputs": [{"name": "pred_boxes", "transformations": pipeline}]}


class ConcatTest(unittest.TestCase):
    def test_appends_raw_outputs_and_adds_a_column_axis_to_flat_tensors(self):
        boxes = numpy.zeros((1, 2, 4), dtype=numpy.float32)
        labels = numpy.array([[3, 7]], dtype=numpy.int64)

        result = run(boxes, ("tensor.concat", {"outputs": ["labels"]}), ctx=context(outputs={"labels": labels}))

        self.assertEqual(result.shape, (1, 2, 5))
        self.assertEqual(result.dtype, numpy.float32)
        self.assertEqual(result[0, :, 4].tolist(), [3.0, 7.0])

    def test_names_a_missing_output_and_lists_the_available_ones(self):
        with self.assertRaisesRegex(ValueError, "keinen Ausgang scores \\(vorhanden: boxes\\)"):
            run(numpy.zeros((2, 4)), ("tensor.concat", {"outputs": ["scores"]}), ctx=context(outputs={"boxes": 1}))

    def test_rejects_shapes_that_do_not_fit_along_the_axis(self):
        with self.assertRaisesRegex(ValueError, "passen entlang Achse -1 nicht"):
            run(numpy.zeros((2, 4)), ("tensor.concat", {"outputs": ["other"]}), ctx=context(outputs={"other": numpy.zeros((3, 1))}))


class DetrDecodingTest(unittest.TestCase):
    """Ende zu Ende über `run_model`: Hilfsausgang ohne eigenen Vertragsausgang, Sigmoid, ohne NMS."""

    def test_reads_boxes_and_class_logits_from_separate_outputs(self):
        [output] = run_model(DetrLikeSession(), detr_payload(), numpy)
        objects = output["transformationValues"]["objects"]

        sigmoid = 1 / (1 + numpy.exp(-2.0))
        self.assertEqual([item["index"] for item in objects], [0, 2])
        self.assertAlmostEqual(objects[0]["score"], sigmoid, places=6)
        self.assertEqual(objects[0]["classIndex"], 0)
        self.assertEqual(objects[1]["classIndex"], 1)
        # Mittelpunkt (0.5, 0.5), Größe (0.2, 0.4) normiert → Ecken in 640 × 480.
        expected = {"left": 256.0, "top": 144.0, "right": 384.0, "bottom": 336.0}
        for key, value in expected.items():
            self.assertAlmostEqual(objects[0]["box"][key], value, places=3)

    def test_rejects_a_contract_output_the_model_does_not_have(self):
        payload = {**detr_payload(), "outputs": [{"name": "scores", "transformations": []}]}

        with self.assertRaisesRegex(ValueError, "keinen Ausgang scores"):
            run_model(DetrLikeSession(), payload, numpy)


class OnnxModelTest(unittest.TestCase):
    """Echtes ONNX-Modell mit zwei Ausgängen (fixtures/detectors/build_fixtures.py), geladen wie im ML-Dienst."""

    def test_decodes_a_two_output_detector_end_to_end(self):
        import onnxruntime

        from novooa_ml.model_execution import session_factory

        session = session_factory(onnxruntime)(str(DETR_LIKE))
        [output] = run_model(session, detr_payload(), numpy)

        objects = output["transformationValues"]["objects"]
        self.assertEqual([(item["index"], item["classIndex"]) for item in objects], [(0, 0), (2, 1)])
        self.assertAlmostEqual(objects[1]["box"]["left"], 448.0, places=3)

    def test_publication_accepts_a_reference_to_an_existing_output(self):
        contract = {
            "inputs": [{"name": "images", "dataType": "float32", "shape": [1, 3, 4, 4]}],
            "outputs": [{"name": "pred_boxes", "dataType": "float32", "shape": [1, 3, 4], "transformations": detr_payload()["outputs"][0]["transformations"]}],
        }
        completed = subprocess.run(
            [sys.executable, "-I", str(PYTHON_ROOT / "onnx_validation_worker.py")],
            input=json.dumps({"artifactPath": str(DETR_LIKE), "contract": contract}),
            capture_output=True, text=True, check=False,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)


class ReferencedOutputsTest(unittest.TestCase):
    def test_finds_output_names_in_parameters_of_any_pipeline(self):
        contract = {"inputs": [], "outputs": [
            {"name": "boxes", "transformations": [{"type": "tensor.concat", "parameters": {"outputs": ["scores", "labels"]}}]},
            {"name": "x", "transformations": [{"type": "keypoints.fromSimcc", "parameters": {"yOutput": "simcc_y"}}]},
        ]}

        self.assertEqual([name for name, _ in referenced_outputs(contract, REGISTRY)], ["scores", "labels", "simcc_y"])

    def test_publication_rejects_a_reference_to_an_output_the_model_lacks(self):
        contract = {
            "inputs": [{"name": "X", "dataType": "float32", "shape": ["dynamic", 2]}],
            "outputs": [{"name": "variable", "dataType": "float32", "shape": ["dynamic", 1], "transformations": [
                {"type": "tensor.concat", "parameters": {"outputs": ["probabilities"]}},
            ]}],
        }
        completed = subprocess.run(
            [sys.executable, "-I", str(PYTHON_ROOT / "onnx_validation_worker.py")],
            input=json.dumps({"artifactPath": str(FIXTURES / "regressor.onnx"), "contract": contract}),
            capture_output=True, text=True, check=False,
        )

        self.assertEqual(completed.returncode, 1)
        self.assertIn("variable: tensor.concat.outputs nennt den Ausgang probabilities", completed.stderr)


if __name__ == "__main__":
    unittest.main()
