import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.input_transforms.registry import TransformationRegistry
from novooa_ml.input_transforms.strategy import InputTransformStrategy


class TransformRegistryTest(unittest.TestCase):
    def test_applies_independent_strategies_in_contract_order(self):
        first = RecordingStrategy("first")
        second = RecordingStrategy("second")
        context = {"calls": []}

        TransformationRegistry([first, second]).apply(
            context,
            [
                {"type": "first", "parameters": {}},
                {"type": "second", "parameters": {}},
            ],
        )

        self.assertEqual(context["calls"], ["first", "second"])

    def test_rejects_an_unregistered_transformation(self):
        registry = TransformationRegistry([])

        with self.assertRaisesRegex(ValueError, "Nicht unterstützte Transformation"):
            registry.apply({}, [{"type": "unknown", "parameters": {}}])


class RecordingStrategy(InputTransformStrategy):
    def __init__(self, name):
        self._name = name

    @property
    def transformation_type(self):
        return self._name

    def transform(self, context, parameters):
        context["calls"].append(self._name)


if __name__ == "__main__":
    unittest.main()
