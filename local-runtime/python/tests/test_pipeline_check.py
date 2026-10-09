import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.pipeline_check import (
    check_contract,
    check_input_pipeline,
    check_output_pipeline,
)

REGISTRY = default_transformation_registry()


def steps(*types):
    return [{"type": transformation_type, "parameters": {}} for transformation_type in types]


class InputPipelineTest(unittest.TestCase):
    def test_accepts_an_image_chain_ending_in_a_tensor(self):
        check_input_pipeline("bild", "image", steps("image.resize", "tensor.scale", "tensor.layout", "tensor.normalize"), REGISTRY)

    def test_accepts_an_image_that_becomes_a_tensor_implicitly(self):
        check_input_pipeline("bild", "image", steps("image.resize"), REGISTRY)
        check_input_pipeline("bild", "image", [], REGISTRY)

    def test_rejects_a_step_that_does_not_fit_the_source(self):
        with self.assertRaisesRegex(ValueError, "Eingang bild: audio.melSpectrogram erwartet audio, erhält image."):
            check_input_pipeline("bild", "image", steps("audio.melSpectrogram"), REGISTRY)

    def test_rejects_image_steps_after_the_tensor(self):
        with self.assertRaisesRegex(ValueError, "image.resize erwartet image, erhält tensor"):
            check_input_pipeline("bild", "image", steps("tensor.scale", "image.resize"), REGISTRY)

    def test_requires_a_tensor_at_the_end(self):
        with self.assertRaisesRegex(ValueError, "Eingang satz: .*Tensor erzeugen, enden aber bei text"):
            check_input_pipeline("satz", "text", [], REGISTRY)

    def test_rejects_unknown_types_and_unsupported_sources(self):
        with self.assertRaisesRegex(ValueError, "Nicht unterstützte Transformation: image.blur"):
            check_input_pipeline("bild", "image", steps("image.blur"), REGISTRY)
        with self.assertRaisesRegex(ValueError, "Quelle datetime wird nicht unterstützt"):
            check_input_pipeline("zeit", "datetime", [], REGISTRY)

    def test_allows_constants_from_any_source(self):
        check_input_pipeline("hilfe", "text", steps("tensor.constant"), REGISTRY)


class OutputPipelineTest(unittest.TestCase):
    def test_region_steps_need_regions(self):
        with self.assertRaisesRegex(ValueError, "Ausgang maske: geometry.mergeRows erwartet regions, erhält tensor."):
            check_output_pipeline("maske", steps("geometry.mergeRows"), REGISTRY)
        check_output_pipeline("maske", steps("mask.connectedComponents", "geometry.mergeRows", "geometry.scaleBounds"), REGISTRY)

    def test_tensor_steps_are_available_in_both_directions(self):
        check_output_pipeline("bild", steps("tensor.layout", "tensor.normalize", "tensor.clip"), REGISTRY)
        check_input_pipeline("bild", "image", steps("tensor.argmax"), REGISTRY)

    def test_results_end_the_tensor_chain(self):
        with self.assertRaisesRegex(ValueError, "tensor.softmax erwartet tensor, erhält json-result"):
            check_output_pipeline("logits", steps("tensor.topK", "tensor.softmax"), REGISTRY)


class ContractCheckTest(unittest.TestCase):
    def test_checks_every_input_and_output(self):
        contract = {
            "inputs": [
                {"name": "bild", "source": "image", "transformations": steps("image.resize")},
                {"name": "vorbereitet", "source": "tensor", "transformations": []},
            ],
            "outputs": [{"name": "logits", "transformations": steps("tensor.softmax", "tensor.topK")}],
        }

        check_contract(contract, REGISTRY)

    def test_rejects_transformations_on_tensor_sources(self):
        contract = {"inputs": [{"name": "roh", "source": "tensor", "transformations": steps("tensor.scale")}], "outputs": []}

        with self.assertRaisesRegex(ValueError, "Eingang roh: Tensor-Quellen erlauben keine Transformationen."):
            check_contract(contract, REGISTRY)

    def test_validates_the_shipped_system_model_manifests(self):
        import json

        for path in sorted((Path(__file__).resolve().parents[2] / "system-models").glob("*.json")):
            with self.subTest(manifest=path.name):
                check_contract(json.loads(path.read_text(encoding="utf-8"))["contract"], REGISTRY)


if __name__ == "__main__":
    unittest.main()
