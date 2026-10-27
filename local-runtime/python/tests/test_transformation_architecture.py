import ast
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformation_capabilities import transformation_capabilities
from novooa_ml.transformations.kinds import ANY, KINDS, SAME

PACKAGE = Path(__file__).resolve().parents[1] / "novooa_ml"

INPUT_TYPES = [
    "audio.fitDuration", "audio.melSpectrogram", "datetime.features", "audio.mono", "audio.normalize", "audio.resample",
    "image.centerCrop", "image.crop", "image.decode", "image.exifTranspose", "image.padToMultiple",
    "image.perspectiveCrop", "image.resize", "image.resizeHeightPad", "image.resizePad",
    "image.resizeShorterSide", "json.features", "json.toTensor", "number.toTensor",
    "tensor.channelOrder", "tensor.clip", "tensor.constant", "tensor.fitLength", "tensor.layout",
    "tensor.normalize", "tensor.reshape", "tensor.scale", "tensor.transpose", "text.kokoroStyle",
    "text.kokoroTokens", "text.piperPhonemeLength", "text.piperPhonemes", "text.toTensor",
    "audio.frames", "image.keepSource", "image.resizeWithin", "image.sizeTensor", "image.tiles",
]
OUTPUT_TYPES = [
    "audio.wav", "geometry.mergeRows", "geometry.scaleBounds", "geometry.toSource", "image.encode",
    "mask.connectedComponents", "mask.toSource", "resource.lookup",
    "mask.textRegions", "sequence.ctcGreedyDecode", "sequence.segments", "tensor.argmax",
    "tensor.clip", "tensor.fitLength", "tensor.l2Normalize", "tensor.nonMaximumSuppression",
    "tensor.reduce", "tensor.reshape", "tensor.round", "tensor.scale", "tensor.sigmoid",
    "tensor.slice", "tensor.softmax", "tensor.squeeze", "tensor.threshold", "tensor.topK",
    "tensor.transpose", "image.applyMask", "keypoints.fromHeatmaps", "keypoints.fromRows",
    "keypoints.fromSimcc", "tensor.concat", "tensor.decodeAnchors", "tensor.decodeGrid",
    "tensor.minMaxScale", "tensor.untile",
]


ALL_TYPES = sorted(set(INPUT_TYPES) | set(OUTPUT_TYPES))
DOMAINS = {"image", "audio", "text", "data", "temporal", "tensor", "vision", "sequence", "resources"}


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
                self.assertIn(declared["produces"], (*KINDS, SAME))


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


class ParameterSchemaLayoutTest(unittest.TestCase):
    """Jede Strategie deklariert jeden Parameter, den sie liest — sonst lehnt der Import ihn ab."""

    def test_every_strategy_declares_its_parameters(self):
        for path in strategy_files():
            with self.subTest(path=str(path.relative_to(PACKAGE))):
                self.assertIn("parameters", class_attributes(path))

    def test_every_parameter_read_by_a_strategy_is_declared(self):
        capabilities = transformation_capabilities()["parameters"]
        for path in strategy_files():
            declared = set(capabilities[transformation_type_of(path)])
            for name in read_parameter_names(path):
                with self.subTest(path=str(path.relative_to(PACKAGE)), parameter=name):
                    self.assertIn(name, declared)

    def test_publishes_parameter_schemas(self):
        parameters = transformation_capabilities()["parameters"]

        self.assertEqual(parameters["image.resize"]["width"], {"type": "integer", "optional": False, "minimum": 1})
        self.assertEqual(sorted(parameters), ALL_TYPES)


class DocumentationTest(unittest.TestCase):
    """Jede Transformation hat eine eigene Notiz im Inhaltsverzeichnis, mit allen Parametern und Tests."""

    def test_every_type_has_a_note_with_all_parameters(self):
        for transformation_type, parameters in transformation_capabilities()["parameters"].items():
            with self.subTest(transformation_type=transformation_type):
                note = note_path(transformation_type)
                self.assertTrue(note.exists(), f"Notiz fehlt: docs/notes/{note.name}")
                text = note.read_text(encoding="utf-8")
                self.assertIn(f"# Transformation `{transformation_type}`", text)
                for name in parameters:
                    self.assertIn(f"`{name}`", text, f"{transformation_type}: {name}")

    def test_every_note_is_listed_in_the_transformation_index(self):
        index = (DOCS / "index" / "transformationen.md").read_text(encoding="utf-8")
        for transformation_type in ALL_TYPES:
            with self.subTest(transformation_type=transformation_type):
                self.assertIn(f"](../notes/{note_path(transformation_type).name})", index)

    def test_every_note_names_existing_tests_that_cover_the_type(self):
        for transformation_type in ALL_TYPES:
            with self.subTest(transformation_type=transformation_type):
                tests = named_tests(note_path(transformation_type).read_text(encoding="utf-8"))
                self.assertTrue(tests, f"{transformation_type}: Abschnitt „Fachliche Tests“ ohne Testdatei")
                for name in tests:
                    path = Path(__file__).resolve().parent / name
                    self.assertTrue(path.exists(), f"{transformation_type}: {name} fehlt")
                    self.assertIn(f'"{transformation_type}"', path.read_text(encoding="utf-8"), name)

    def test_no_note_exists_for_a_removed_type(self):
        notes = {path.name for path in (DOCS / "notes").glob("transformation-*.md")}
        self.assertEqual(notes, {note_path(transformation_type).name for transformation_type in ALL_TYPES})


DOCS = PACKAGE.parents[2] / "docs"


def note_path(transformation_type):
    """`image.resizePad` → `docs/notes/transformation-image-resize-pad.md`."""
    kebab = re.sub(r"(?<=[a-z0-9])([A-Z])", r"-\1", transformation_type.replace(".", "-")).lower()
    return DOCS / "notes" / f"transformation-{kebab}.md"


def named_tests(text):
    """Testdateien, die der Abschnitt „Fachliche Tests“ einer Notiz verlinkt."""
    section = text.split("## Fachliche Tests", 1)[-1].split("\n## ", 1)[0] if "## Fachliche Tests" in text else ""
    return re.findall(r"\[`(test_\w+\.py)`\]", section)


def class_attributes(path):
    tree = ast.parse(path.read_text(encoding="utf-8"))
    return {
        target.id
        for node in tree.body if isinstance(node, ast.ClassDef)
        for statement in node.body if isinstance(statement, ast.Assign)
        for target in statement.targets if isinstance(target, ast.Name)
    }


def transformation_type_of(path):
    match = re.search(r'return "([^"]+)"', path.read_text(encoding="utf-8"))
    return match.group(1)


def read_parameter_names(path):
    """Schlüssel, die die Strategie-Datei und ihre lokalen Helfer aus `parameters` lesen."""
    sources = [path.read_text(encoding="utf-8")]
    for helper in re.findall(r"^from \.(\w+) import", sources[0], flags=re.M):
        helper_path = path.parent / f"{helper}.py"
        # Importiert eine Strategie Hilfsfunktionen aus einer anderen Strategie, zählen deren
        # Parameter nicht mit.
        if not strategy_classes(helper_path):
            sources.append(helper_path.read_text(encoding="utf-8"))
    names = set()
    for source in sources:
        names |= set(re.findall(r'parameters(?:\.get\(|\[)"(\w+)"', source))
        if "axis_of(" in source:
            names.add("axis")
    return names


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
