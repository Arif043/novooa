"""Fachlicher Referenztest für PP-OCRv6 Small (Detektor und Recognizer aus models/pp-ocr-v6).

Unsere Manifest-Pipeline (Transformationen des ML-Dienstes, echte ONNX-Modelle) gegen das gespeicherte
Ergebnis von RapidOCR mit denselben ONNX-Dateien (fixtures/ocr/build_reference.py) und gegen den
wahren Text des synthetischen Belegs.
"""

import base64
import json
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy

from novooa_ml.model_execution import run_model, session_factory
from novooa_ml.model_input.worker import transform_payload

ROOT = Path(__file__).resolve().parents[3]
FIXTURES = Path(__file__).resolve().parent / "fixtures" / "ocr"
DETECTOR = ROOT / "models" / "pp-ocr-v6" / "detector"
RECOGNIZER = ROOT / "models" / "pp-ocr-v6" / "recognizer"
ITERATION = "$iteration.value.bounds."

try:
    import onnxruntime
except ImportError:  # pragma: no cover - ohne onnxruntime gibt es keinen Lauf
    onnxruntime = None


def run_manifest(folder, image_base64, bounds=None):
    """Wie die Runtime: Eingangspipeline, Inferenz, Ausgangspipeline; `$iteration` wie in der Schleife ersetzt."""
    contract = json.loads((folder / "model.json").read_text(encoding="utf-8"))["contract"]
    [input_definition], [output_definition] = contract["inputs"], contract["outputs"]
    steps = json.loads(json.dumps(input_definition["transformations"]).replace('"' + ITERATION, '"#'))
    for step in steps:
        for key, value in step["parameters"].items():
            if isinstance(value, str) and value.startswith("#"):
                step["parameters"][key] = bounds[value[1:]]
    payload = {"input": {**input_definition, "transformations": steps}, "source": {"type": "image", "dataBase64": image_base64}}
    tensor = transform_payload(payload)["tensor"]
    session = session_factory(onnxruntime)(str(folder / "model.onnx"))
    [output] = run_model(session, {"inputs": [tensor], "outputs": [output_definition]}, numpy)
    return output["transformationValues"]["tensor"]


def recognized_lines(image_base64):
    regions = run_manifest(DETECTOR, image_base64)
    lines = []
    for region in regions:
        recognition = run_manifest(RECOGNIZER, image_base64, region["bounds"])
        result = recognition[0] if isinstance(recognition, list) else recognition
        lines.append({"bounds": region["bounds"], "text": result["text"]})
    return sorted(lines, key=lambda line: line["bounds"]["top"])


def without_spaces(text):
    return re.sub(r"\s+", "", text)


def iou(left, right):
    width = min(left["left"] + left["width"], right["left"] + right["width"]) - max(left["left"], right["left"])
    height = min(left["top"] + left["height"], right["top"] + right["height"]) - max(left["top"], right["top"])
    overlap = max(0, width) * max(0, height)
    return overlap / (left["width"] * left["height"] + right["width"] * right["height"] - overlap)


@unittest.skipIf(onnxruntime is None, "onnxruntime fehlt")
class PpOcrV6ReferenceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.reference = json.loads((FIXTURES / "pp_ocr_v6_reference.json").read_text(encoding="utf-8"))
        image = base64.b64encode((FIXTURES / "receipt_de.png").read_bytes()).decode("ascii")
        cls.lines = recognized_lines(image)

    def test_finds_every_line_of_the_reference(self):
        self.assertEqual(len(self.lines), len(self.reference["lines"]))

    def test_boxes_match_the_reference_detection(self):
        for ours, theirs in zip(self.lines, self.reference["lines"], strict=True):
            with self.subTest(text=theirs["text"]):
                self.assertGreaterEqual(iou(ours["bounds"], theirs["bounds"]), 0.7)

    def test_texts_match_the_reference_and_the_truth(self):
        for ours, theirs, truth in zip(self.lines, self.reference["lines"], self.reference["truth"], strict=True):
            with self.subTest(truth=truth):
                # Leerzeichen setzt das Modell nicht immer; verglichen wird der Text ohne sie.
                self.assertEqual(without_spaces(ours["text"]), without_spaces(theirs["text"]))
                self.assertEqual(without_spaces(ours["text"]), without_spaces(truth))

    def test_reference_was_made_with_the_shipped_models(self):
        import hashlib

        for name, folder in (("detector", DETECTOR), ("recognizer", RECOGNIZER)):
            self.assertEqual(hashlib.sha256((folder / "model.onnx").read_bytes()).hexdigest(), self.reference["models"][name])


if __name__ == "__main__":
    unittest.main()
