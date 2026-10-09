import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.context import TransformationContext
from novooa_ml.model_output.worker import transformation_values
from onnx_worker import transformed_output_tensors


class OutputTransformationRegistryTest(unittest.TestCase):
    def setUp(self):
        import numpy

        self.numpy = numpy
        self.registry = default_transformation_registry()

    def test_converts_a_mask_into_generic_regions(self):
        values = transformation_values(self.registry, 
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


    def test_groups_mask_fragments_into_scored_text_regions(self):
        values = transformation_values(self.registry, 
            self.numpy.array([[[[0, .9, .9, 0, 0, .8, .8, 0], [0, .9, .9, 0, 0, .8, .8, 0], [0, 0, 0, 0, 0, 0, 0, 0], [0, .7, .7, 0, 0, .7, .7, 0]]]]),
            [{
                "type": "mask.textRegions",
                "result": "regions",
                "parameters": {
                    "threshold": .5,
                    "minimumPixels": 4,
                    "minimumScore": .6,
                    "dilationWidth": 3,
                    "dilationHeight": 1,
                },
            }],
            self.context(),
        )

        self.assertEqual(len(values["regions"]), 2)
        self.assertEqual(values["regions"][0]["pixelCount"], 8)
        self.assertGreater(values["regions"][0]["score"], .8)
        self.assertEqual(values["regions"][1]["bounds"]["top"], 3)


    def test_merges_regions_sharing_a_text_row(self):
        values = transformation_values(self.registry, 
            [
                {"bounds": {"left": 10, "top": 20, "width": 80, "height": 18}, "pixelCount": 20, "score": .9},
                {"bounds": {"left": 200, "top": 24, "width": 30, "height": 18}, "pixelCount": 10, "score": .8},
                {"bounds": {"left": 10, "top": 60, "width": 80, "height": 18}, "pixelCount": 20, "score": .9},
            ],
            [{
                "type": "geometry.mergeRows",
                "result": "rows",
                "parameters": {"minimumVerticalOverlap": .5},
            }],
            self.context(),
        )

        self.assertEqual(len(values["rows"]), 2)
        self.assertEqual(values["rows"][0]["bounds"], {"left": 10, "top": 20, "width": 220, "height": 22})
        self.assertEqual(values["rows"][0]["memberCount"], 2)

    def test_decodes_ctc_logits_with_manifest_labels(self):
        values = transformation_values(self.registry, 
            self.numpy.array([[[0, 5, 0], [0, 5, 0], [5, 0, 0], [0, 0, 5]]]),
            [{"type": "sequence.ctcGreedyDecode", "result": "lines", "parameters": {"labels": ["", "A", "B"], "blankIndex": 0}}],
            self.context(),
        )

        self.assertEqual(values["lines"][0]["text"], "AB")

    def test_limits_ctc_decoding_to_allowed_characters(self):
        values = transformation_values(self.registry, 
            self.numpy.array([[[0, 2, 5], [0, 4, 3]]]),
            [{"type": "sequence.ctcGreedyDecode", "result": "lines", "parameters": {"labels": ["", "A", "中"], "blankIndex": 0, "allowedCharacters": "A", "collapseRepeated": False}}],
            self.context(),
        )

        self.assertEqual(values["lines"][0]["text"], "AA")

    def test_uses_the_declared_top_k_parameter(self):
        values = transformation_values(self.registry, 
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
        return TransformationContext(self.numpy, output_name="scores", output_parameters=parameters or [])


if __name__ == "__main__":
    unittest.main()
