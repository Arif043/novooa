import ast
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformation_capabilities import transformation_capabilities
from novooa_ml.transformations.kinds import ANY, KINDS

PACKAGE = Path(__file__).resolve().parents[1] / "novooa_ml"

INPUT_TYPES = [
    "audio.fitDuration", "audio.melSpectrogram", "datetime.features", "audio.mono", "audio.normalize", "audio.resample",
    "image.centerCrop", "image.crop", "image.decode", "image.exifTranspose", "image.padToMultiple",
    "image.perspectiveCrop", "image.resize", "image.resizeHeightPad", "image.resizePad",
    "image.resizeShorterSide", "json.features", "json.toTensor", "number.toTensor",
    "tensor.channelOrder", "tensor.clip", "tensor.constant", "tensor.fitLength", "tensor.layout",
    "tensor.normalize", "tensor.reshape", "tensor.scale", "tensor.transpose", "text.kokoroStyle",
    "text.kokoroTokens", "text.piperPhonemeLength", "text.piperPhonemes",
]
OUTPUT_TYPES = [
    "audio.wav", "geometry.mergeRows", "geometry.scaleBounds", "mask.connectedComponents",
    "mask.textRegions", "sequence.ctcGreedyDecode", "sequence.segments", "tensor.argmax",
    "tensor.clip", "tensor.fitLength", "tensor.l2Normalize", "tensor.nonMaximumSuppression",
    "tensor.reduce", "tensor.reshape", "tensor.round", "tensor.scale", "tensor.sigmoid",
    "tensor.slice", "tensor.softmax", "tensor.squeeze", "tensor.threshold", "tensor.topK",
    "tensor.transpose",
]


ALL_TYPES = sorted(set(INPUT_TYPES) | set(OUTPUT_TYPES))
DOMAINS = {"image", "audio", "text", "data", "temporal", "tensor", "vision", "sequence"}


class CapabilitySnapshotTest(unittest.TestCase):
    def test_offers_every_type_in_both_directions(self):
        capabilities = transformation_capabilities()

        self.assertEqual(sorted(capabilities["inputTransformationTypes"]), ALL_TYPES)
        self.assertEqual(sorted(capabilities["outputTransformationTypes"]), ALL_TYPES)

    def test_publishes_valid_kinds_for_every_type(self):
        kinds = transformation_capabilities()["kinds"]

        self.assertEqual(sorted(kinds), ALL_TYPES)
        for transformation_type, declared in kinds.items():
            with self.subTest(transformation_type=transformation_type):
                self.assertTrue(declared["accepts"])
                self.assertTrue(set(declared["accepts"]) <= set(KINDS) | {ANY})
                self.assertIn(declared["produces"], KINDS)


class StrategyLayoutTest(unittest.TestCase):
    """Ein Katalog nach Fachbereich: eine Strategie je Datei, keine Trennung nach Richtung."""

    def test_each_strategy_lives_in_its_own_file(self):
        for path in strategy_files():
            with self.subTest(path=str(path.relative_to(PACKAGE))):
                self.assertEqual(len(strategy_classes(path)), 1)

    def test_every_transformation_type_has_a_file(self):
        self.assertEqual(len(list(strategy_files())), len(ALL_TYPES))

    def test_strategies_are_grouped_by_domain_not_by_direction(self):
        for path in strategy_files():
            with self.subTest(path=str(path.relative_to(PACKAGE))):
                self.assertIn(path.parent.name, DOMAINS)
        for legacy in ("input_transforms", "output_transforms", "transformations/shared"):
            self.assertFalse((PACKAGE / legacy).exists(), legacy)


def strategy_files():
    for path in sorted((PACKAGE / "transformations").rglob("*.py")):
        if strategy_classes(path):
            yield path


def strategy_classes(path):
    tree = ast.parse(path.read_text(encoding="utf-8"))
    return [
        node.name for node in tree.body
        if isinstance(node, ast.ClassDef) and node.name.endswith("Strategy")
        and any(getattr(base, "id", "") == "TransformationStrategy" for base in node.bases)
    ]


if __name__ == "__main__":
    unittest.main()
