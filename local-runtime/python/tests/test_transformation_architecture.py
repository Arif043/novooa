import ast
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformation_capabilities import transformation_capabilities

PACKAGE = Path(__file__).resolve().parents[1] / "novooa_ml"

INPUT_TYPES = [
    "audio.fitDuration", "audio.melSpectrogram", "audio.mono", "audio.normalize", "audio.resample",
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


class CapabilitySnapshotTest(unittest.TestCase):
    def test_offers_exactly_the_known_transformation_types(self):
        capabilities = transformation_capabilities()

        self.assertEqual(sorted(capabilities["inputTransformationTypes"]), INPUT_TYPES)
        self.assertEqual(sorted(capabilities["outputTransformationTypes"]), OUTPUT_TYPES)


class StrategyLayoutTest(unittest.TestCase):
    """Ein- und Ausgang folgen derselben Struktur: eine Strategie je Datei, ein gemeinsamer Kern."""

    def test_each_strategy_lives_in_its_own_file(self):
        for path in strategy_files():
            with self.subTest(path=str(path.relative_to(PACKAGE))):
                self.assertEqual(len(strategy_classes(path)), 1)

    def test_every_transformation_type_has_a_file(self):
        files = list(strategy_files())

        self.assertEqual(len(files), len(set(INPUT_TYPES) | set(OUTPUT_TYPES)))

    def test_both_directions_use_the_shared_core(self):
        for direction in ("input_transforms", "output_transforms"):
            with self.subTest(direction=direction):
                self.assertFalse((PACKAGE / direction / "registry.py").exists())
                self.assertFalse((PACKAGE / direction / "context.py").exists())
                self.assertFalse((PACKAGE / direction / "strategy.py").exists())


def strategy_files():
    roots = [PACKAGE / "input_transforms", PACKAGE / "output_transforms", PACKAGE / "transformations" / "shared"]
    for root in roots:
        for path in sorted(root.rglob("*.py")):
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
