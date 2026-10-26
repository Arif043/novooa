import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import json

from ml_test_support import REGISTRY, shipped_model_manifests
from novooa_ml.transformations.pipeline_check import check_contract


def contract(input_steps=(), output_steps=(), settings=()):
    return {
        "inputs": [{"name": "bild", "source": "image", "transformations": list(input_steps)}],
        "outputs": [{"name": "scores", "transformations": list(output_steps)}],
        "settings": list(settings),
    }


def step(kind, **parameters):
    return {"type": kind, "parameters": parameters}


class ParameterCheckTest(unittest.TestCase):
    def assert_rejected(self, value, message):
        with self.assertRaisesRegex(ValueError, message):
            check_contract(value, REGISTRY)

    def test_accepts_complete_parameters(self):
        check_contract(contract(
            [step("image.resize", width=224, height=224), step("tensor.scale", factor=1 / 255)],
            [step("tensor.softmax"), step("tensor.topK", k=3)],
        ), REGISTRY)

    def test_names_a_missing_required_parameter(self):
        self.assert_rejected(contract([step("image.resize", width=224)]), "Eingang bild: image.resize: Der Parameter height fehlt.")

    def test_rejects_a_misspelled_parameter_with_a_suggestion(self):
        self.assert_rejected(
            contract(output_steps=[step("tensor.nonMaximumSuppression", box={"left": 0, "top": 1, "right": 2, "bottom": 3}, scoreIndex=4, iouTreshold=0.4)]),
            "Ausgang scores: tensor.nonMaximumSuppression: Unbekannter Parameter iouTreshold — gemeint ist vermutlich iouThreshold.",
        )

    def test_rejects_values_of_the_wrong_type_or_range(self):
        self.assert_rejected(contract(output_steps=[step("tensor.topK", k=0)]), "Ausgang scores: tensor.topK: k erwartet eine ganze Zahl ≥ 1, erhält 0.")
        self.assert_rejected(contract([step("image.decode", colorSpace="cmyk")]), "image.decode: colorSpace erwartet einen der Werte")

    def test_names_nested_paths(self):
        self.assert_rejected(
            contract(output_steps=[step("tensor.nonMaximumSuppression", box={"left": 0, "top": 1, "right": "x", "bottom": 3}, scoreIndex=4)]),
            "box.right erwartet eine ganze Zahl ≥ 0",
        )

    def test_checks_bindings_against_the_settings_of_the_contract(self):
        slider = {"name": "anzahl", "label": "Anzahl", "control": {"type": "slider", "initial": 3, "minimum": 1, "maximum": 10, "step": 1}}
        checkbox = {"name": "anzahl", "label": "Anzahl", "control": {"type": "checkbox", "initial": True}}

        check_contract(contract(output_steps=[step("tensor.topK", k="$anzahl")], settings=[slider]), REGISTRY)
        self.assert_rejected(
            contract(output_steps=[step("tensor.topK", k="$anzahl")], settings=[checkbox]),
            r"tensor.topK: k ist an das Setting anzahl \(Checkbox\) gebunden, erwartet wird eine ganze Zahl ≥ 1.",
        )

    def test_leaves_workflow_bindings_to_the_runtime(self):
        check_contract(contract(output_steps=[step("tensor.threshold", value="$schwelle.value")]), REGISTRY)

    def test_still_accepts_the_old_top_k_description(self):
        legacy = {"name": "k", "label": "Anzahl", "default": 3, "minimum": 1, "maximum": 5}

        check_contract(contract(output_steps=[step("tensor.topK", parameter=legacy)]), REGISTRY)


class ShippedManifestTest(unittest.TestCase):
    def test_every_shipped_model_manifest_passes_the_parameter_check(self):
        manifests = shipped_model_manifests()
        self.assertTrue(any(path.name == "model.json" for path in manifests))
        for path in manifests:
            with self.subTest(manifest=str(path)):
                check_contract(json.loads(path.read_text(encoding="utf-8"))["contract"], REGISTRY)

    def test_documented_classifier_and_ocr_examples_pass(self):
        for path in sorted((Path(__file__).resolve().parent / "fixtures" / "contracts").glob("*.json")):
            with self.subTest(contract=path.name):
                check_contract(json.loads(path.read_text(encoding="utf-8")), REGISTRY)


if __name__ == "__main__":
    unittest.main()
