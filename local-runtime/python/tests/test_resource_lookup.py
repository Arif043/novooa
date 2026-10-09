import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import json

import numpy

from ml_test_support import REGISTRY, context
from novooa_ml.model_output.worker import transform_outputs
from novooa_ml.transformations.pipeline_check import check_contract, check_output_pipeline

RESOURCES = {
    "labels.txt": "Hintergrund\nKatze\nHund\n".encode("utf-8"),
    "labels.json": json.dumps(["Ä", "Ö", "Ü"]).encode("utf-8"),
    "kaputt.json": b'{"kein": "array"}',
}


def lookup(value, **parameters):
    ctx = context(resource_reader=lambda name: RESOURCES[name])
    return REGISTRY.run(value, [{"type": "resource.lookup", "parameters": parameters}], ctx).value


class ResourceLookupTest(unittest.TestCase):
    def test_adds_the_label_from_a_text_file_with_one_label_per_line(self):
        result = lookup([{"index": 2, "value": 0.9}, {"index": 0, "value": 0.1}], resource="labels.txt")

        self.assertEqual(result, [{"index": 2, "value": 0.9, "label": "Hund"}, {"index": 0, "value": 0.1, "label": "Hintergrund"}])

    def test_reads_json_lists_and_custom_field_names(self):
        detections = [{"index": 7, "classIndex": 1, "box": {}}]

        result = lookup(detections, resource="labels.json", format="json", key="classIndex", field="klasse")

        self.assertEqual(result[0]["klasse"], "Ö")
        self.assertEqual(result[0]["index"], 7)

    def test_leaves_the_input_untouched(self):
        items = [{"index": 1}]

        lookup(items, resource="labels.txt")

        self.assertEqual(items, [{"index": 1}])

    def test_names_out_of_range_indexes_and_missing_keys(self):
        with self.assertRaisesRegex(ValueError, "resource.lookup: Der Index 3 liegt außerhalb der 3 Labels in labels.txt"):
            lookup([{"index": 3}], resource="labels.txt")
        with self.assertRaisesRegex(ValueError, "resource.lookup: Eintrag 0 hat keinen ganzzahligen Schlüssel classIndex"):
            lookup([{"index": 1}], resource="labels.txt", key="classIndex")

    def test_rejects_resources_that_are_not_label_lists(self):
        with self.assertRaisesRegex(ValueError, "kaputt.json ist keine Liste von Texten"):
            lookup([{"index": 0}], resource="kaputt.json", format="json")
        with self.assertRaisesRegex(ValueError, "keinen Zugriff auf Modellressourcen"):
            REGISTRY.run([{"index": 0}], [{"type": "resource.lookup", "parameters": {"resource": "labels.txt"}}], context())


class ResourceLookupChainTest(unittest.TestCase):
    def test_follows_top_k_and_detections_but_not_raw_tensors(self):
        step = {"type": "resource.lookup", "parameters": {"resource": "labels.txt"}}
        check_output_pipeline("scores", [{"type": "tensor.topK", "parameters": {}}, step], REGISTRY)
        check_output_pipeline("boxen", [{"type": "tensor.nonMaximumSuppression", "parameters": {}}, step], REGISTRY)
        with self.assertRaisesRegex(ValueError, "resource.lookup erwartet"):
            check_output_pipeline("roh", [step], REGISTRY)

    def test_checks_its_parameters_at_import(self):
        contract = {"inputs": [], "outputs": [{"name": "scores", "transformations": [
            {"type": "tensor.topK", "parameters": {"k": 3}},
            {"type": "resource.lookup", "parameters": {"resource": "labels.txt", "format": "csv"}},
        ]}]}

        with self.assertRaisesRegex(ValueError, "format erwartet einen der Werte lines, json"):
            check_contract(contract, REGISTRY)

    def test_labels_top_classes_through_the_output_worker(self):
        definitions = [{"name": "scores", "transformations": [
            {"type": "tensor.topK", "parameters": {"k": 2}},
            {"type": "resource.lookup", "parameters": {"resource": "labels.txt"}},
        ]}]

        [output] = transform_outputs(
            [("scores", numpy.array([0.1, 0.3, 0.6]))], definitions, numpy, resource_reader=lambda name: RESOURCES[name],
        )

        self.assertEqual([item["label"] for item in output["transformationValues"]["tensor"]], ["Hund", "Katze"])


if __name__ == "__main__":
    unittest.main()
