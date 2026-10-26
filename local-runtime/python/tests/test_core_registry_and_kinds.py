import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ml_test_support import REGISTRY, context
from novooa_ml.transformations.discovery import strategy_instances
from novooa_ml.transformations.kinds import (
    ANY,
    AUDIO,
    IMAGE,
    JSON,
    REGIONS,
    TENSOR,
    TEXT,
    accepts,
    is_tensor_ready,
)
from novooa_ml.transformations.registry import TransformationRegistry
from novooa_ml.transformations.strategy import TransformationStrategy


class Append(TransformationStrategy):
    accepts = (ANY,)
    produces = JSON

    def __init__(self, name):
        self._name = name

    @property
    def transformation_type(self):
        return self._name

    def transform(self, value, parameters, context):
        return [*value, parameters.get("mark", self._name)]


class RegistryTest(unittest.TestCase):
    def test_passes_each_steps_parameters_and_keeps_named_results(self):
        registry = TransformationRegistry([Append("a"), Append("b")])

        result = registry.run(
            [],
            [
                {"type": "a", "parameters": {"mark": "erster"}, "result": "zwischen"},
                {"type": "b", "parameters": {}},
                {"type": "a", "parameters": {}, "result": "ende"},
            ],
            context(),
        )

        self.assertEqual(result.value, ["erster", "b", "a"])
        self.assertEqual(result.results, {"zwischen": ["erster"], "ende": ["erster", "b", "a"]})

    def test_leaves_the_start_value_untouched(self):
        start = ["unverändert"]

        TransformationRegistry([Append("a")]).run(start, [{"type": "a", "parameters": {}}], context())

        self.assertEqual(start, ["unverändert"])

    def test_an_empty_pipeline_returns_the_start_value(self):
        result = TransformationRegistry([]).run("Wert", [], context())

        self.assertEqual((result.value, result.results), ("Wert", {}))

    def test_rejects_duplicate_types(self):
        with self.assertRaisesRegex(ValueError, "nur einmal registriert"):
            TransformationRegistry([Append("a"), Append("a")])

    def test_reports_the_kinds_of_a_type(self):
        self.assertEqual(REGISTRY.kinds_of("geometry.mergeRows"), ((REGIONS,), REGIONS))
        self.assertIsNone(REGISTRY.kinds_of("image.blur"))


class DiscoveryTest(unittest.TestCase):
    def test_finds_every_concrete_strategy_once(self):
        strategies = strategy_instances("novooa_ml.transformations")
        types = [strategy.transformation_type for strategy in strategies]

        self.assertEqual(len(types), len(set(types)))
        self.assertEqual(sorted(types), sorted(REGISTRY.supported_types))
        self.assertTrue(all(isinstance(strategy, TransformationStrategy) for strategy in strategies))

    def test_finds_strategies_in_subpackages(self):
        types = {strategy.transformation_type for strategy in strategy_instances("novooa_ml.transformations.vision")}

        self.assertEqual(types, {
            "mask.connectedComponents", "mask.textRegions", "mask.toSource", "geometry.mergeRows",
            "geometry.scaleBounds", "geometry.toSource", "tensor.nonMaximumSuppression",
            "tensor.decodeGrid", "tensor.decodeAnchors", "keypoints.fromRows", "keypoints.fromHeatmaps",
            "keypoints.fromSimcc",
        })


class KindsTest(unittest.TestCase):
    def test_accepts_declared_kinds_and_wildcards(self):
        self.assertTrue(accepts((IMAGE,), IMAGE))
        self.assertTrue(accepts((ANY,), TEXT))
        self.assertFalse(accepts((AUDIO,), IMAGE))

    def test_media_counts_as_tensor_but_not_the_other_way_round(self):
        self.assertTrue(accepts((TENSOR,), IMAGE))
        self.assertTrue(accepts((TENSOR,), AUDIO))
        self.assertFalse(accepts((IMAGE,), TENSOR))
        self.assertFalse(accepts((TENSOR,), TEXT))

    def test_knows_which_kinds_can_reach_the_model(self):
        self.assertTrue(all(is_tensor_ready(kind) for kind in (TENSOR, IMAGE, AUDIO)))
        self.assertFalse(any(is_tensor_ready(kind) for kind in (TEXT, JSON, REGIONS)))


if __name__ == "__main__":
    unittest.main()
