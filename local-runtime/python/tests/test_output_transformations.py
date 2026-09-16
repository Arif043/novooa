import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.output_transforms.default_registry import default_output_transformation_registry
from novooa_ml.output_transforms.registry import OutputTransformationContext
from onnx_worker import transformed_output_tensors


class OutputTransformationRegistryTest(unittest.TestCase):
    def setUp(self):
        import numpy

        self.numpy = numpy
        self.registry = default_output_transformation_registry()

    def test_converts_a_mask_into_generic_regions(self):
        values = self.registry.process(
            self.numpy.array([[[0, 1], [1, 1]]]),
            [
                {"type": "tensor.threshold", "parameters": {"value": 0.5}},
                {"type": "mask.connectedComponents", "result": "regions", "parameters": {"minimumPixels": 2}},
            ],
            self.context(),
        )

        self.assertEqual(
            values["regions"],
            [{"bounds": {"left": 0, "top": 0, "width": 2, "height": 2}, "pixelCount": 3}],
        )

    def test_decodes_ctc_logits_with_manifest_labels(self):
        values = self.registry.process(
            self.numpy.array([[[0, 5, 0], [0, 5, 0], [5, 0, 0], [0, 0, 5]]]),
            [{"type": "sequence.ctcGreedyDecode", "result": "lines", "parameters": {"labels": ["", "A", "B"], "blankIndex": 0}}],
            self.context(),
        )

        self.assertEqual(values["lines"][0]["text"], "AB")

    def test_uses_the_declared_top_k_parameter(self):
        values = self.registry.process(
            self.numpy.array([[1, 2, 3]]),
            [{"type": "tensor.topK", "result": "top", "parameters": {"parameter": {"name": "k", "default": 1, "minimum": 1, "maximum": 3}}}],
            self.context([{"outputName": "scores", "name": "k", "value": 2}]),
        )

        self.assertEqual(values["top"][0]["index"], 2)
        self.assertEqual(len(values["top"]), 2)

    def test_preserves_the_onnx_output_name_when_serializing_transformed_values(self):
        outputs = transformed_output_tensors(
            {
                "outputs": [{
                    "name": "scores", "dataType": "float32", "shape": [1, 3],
                    "transformations": [],
                }],
                "outputParameters": [],
            },
            [self.numpy.array([[1, 2, 3]], dtype=self.numpy.float32)],
            self.numpy,
        )

        self.assertEqual(outputs[0]["name"], "scores")
        self.assertEqual(outputs[0]["transformationValues"]["tensor"], [[1.0, 2.0, 3.0]])

    def context(self, parameters=None):
        return OutputTransformationContext("scores", parameters or [], self.numpy)


if __name__ == "__main__":
    unittest.main()
