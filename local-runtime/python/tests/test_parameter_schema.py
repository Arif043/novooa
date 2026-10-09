import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import ml_test_support  # noqa: F401  (setzt den Paketpfad)
from novooa_ml.transformations.schema import (
    Boolean,
    Choice,
    Integer,
    ListOf,
    MapOf,
    Number,
    OneOf,
    Record,
    Text,
)


class ScalarSchemaTest(unittest.TestCase):
    def test_integer_checks_type_and_bounds(self):
        Integer(minimum=1).validate(3, "k")
        for value in [0, 1.5, True, "3"]:
            with self.subTest(value=value), self.assertRaisesRegex(ValueError, "k erwartet eine ganze Zahl ≥ 1, erhält"):
                Integer(minimum=1).validate(value, "k")
        with self.assertRaisesRegex(ValueError, "background erwartet eine ganze Zahl zwischen 0 und 255, erhält 300"):
            Integer(minimum=0, maximum=255).validate(300, "background")

    def test_number_accepts_integers_and_floats_but_not_booleans(self):
        Number(minimum=0, maximum=1).validate(0.5, "x")
        Number().validate(3, "x")
        with self.assertRaisesRegex(ValueError, "x erwartet eine Zahl, erhält True"):
            Number().validate(True, "x")
        with self.assertRaisesRegex(ValueError, "x erwartet eine Zahl ≤ 1"):
            Number(maximum=1).validate(2, "x")

    def test_boolean_text_and_choice(self):
        Boolean().validate(False, "b")
        Text().validate("de", "language")
        Choice("rgb", "grayscale").validate("rgb", "colorSpace")
        with self.assertRaisesRegex(ValueError, "b erwartet einen Wahrheitswert"):
            Boolean().validate("ja", "b")
        with self.assertRaisesRegex(ValueError, "language erwartet einen nicht leeren Text"):
            Text().validate("", "language")
        with self.assertRaisesRegex(ValueError, "colorSpace erwartet einen der Werte rgb, grayscale, erhält 'cmyk'"):
            Choice("rgb", "grayscale").validate("cmyk", "colorSpace")


class CompositeSchemaTest(unittest.TestCase):
    def test_lists_check_length_and_name_the_failing_index(self):
        points = ListOf(Number(), length=8)
        points.validate([0] * 8, "points")
        with self.assertRaisesRegex(ValueError, "points erwartet eine Liste mit genau 8 Einträgen"):
            points.validate([0] * 4, "points")
        with self.assertRaisesRegex(ValueError, r"mean\[1\] erwartet eine Zahl"):
            ListOf(Number()).validate([1, "x"], "mean")
        with self.assertRaisesRegex(ValueError, "labels erwartet eine Liste mit mindestens 1 Eintrag"):
            ListOf(Text()).validate([], "labels")

    def test_records_report_missing_unknown_and_nested_fields(self):
        box = Record({"left": Integer(minimum=0), "top": Integer(minimum=0), "score": Number(optional=True)})
        box.validate({"left": 0, "top": 1}, "box")
        with self.assertRaisesRegex(ValueError, "Der Parameter box.top fehlt"):
            box.validate({"left": 0}, "box")
        with self.assertRaisesRegex(ValueError, "Unbekannter Parameter box.lefft — gemeint ist vermutlich box.left"):
            box.validate({"lefft": 0, "left": 0, "top": 0}, "box")
        with self.assertRaisesRegex(ValueError, "box.left erwartet eine ganze Zahl ≥ 0"):
            box.validate({"left": -1, "top": 0}, "box")

    def test_nested_paths_through_lists_of_records(self):
        features = ListOf(Record({"field": Text(), "std": Number(optional=True)}))

        with self.assertRaisesRegex(ValueError, r"features\[1\].std erwartet eine Zahl"):
            features.validate([{"field": "a"}, {"field": "b", "std": "x"}], "features")

    def test_maps_and_alternatives(self):
        phonemes = MapOf(OneOf(Integer(minimum=0), ListOf(Integer(minimum=0), length=1)))
        phonemes.validate({"a": 3, "b": [4]}, "phonemeIdMap")
        with self.assertRaisesRegex(ValueError, "phonemeIdMap.c erwartet eine ganze Zahl ≥ 0 oder eine Liste mit genau 1 Eintrag"):
            phonemes.validate({"c": "x"}, "phonemeIdMap")
        with self.assertRaisesRegex(ValueError, "phonemeIdMap erwartet ein Objekt"):
            phonemes.validate([1], "phonemeIdMap")

    def test_describes_itself_as_json(self):
        schema = Record({
            "width": Integer(minimum=1),
            "alignment": Choice("topLeft", "center", optional=True, default="topLeft"),
            "mean": ListOf(Number(), length=3),
        })

        self.assertEqual(schema.describe(), {"type": "record", "optional": False, "fields": {
            "width": {"type": "integer", "optional": False, "minimum": 1},
            "alignment": {"type": "choice", "optional": True, "default": "topLeft", "options": ["topLeft", "center"]},
            "mean": {"type": "list", "optional": False, "items": {"type": "number", "optional": False}, "length": 3},
        }})


SLIDER = {"name": "anzahl", "label": "Anzahl", "control": {"type": "slider", "initial": 3, "minimum": 1, "maximum": 10, "step": 1}}
CHECKBOX = {"name": "weich", "label": "Weich", "control": {"type": "checkbox", "initial": True}}
RADIO = {"name": "modus", "label": "Modus", "control": {"type": "radioGroup", "initial": "peak", "options": [
    {"value": "peak", "label": "Spitze"}, {"value": "rms", "label": "Effektiv"},
]}}


class SettingBindingTest(unittest.TestCase):
    settings = {setting["name"]: setting for setting in (SLIDER, CHECKBOX, RADIO)}

    def test_accepts_bindings_to_matching_settings(self):
        Integer(minimum=1).validate("$anzahl", "k", self.settings)
        Boolean().validate("$weich", "applySoftmax", self.settings)
        Choice("peak", "rms").validate("$modus", "mode", self.settings)

    def test_rejects_settings_whose_control_does_not_fit(self):
        with self.assertRaisesRegex(ValueError, "k ist an das Setting weich \\(Checkbox\\) gebunden, erwartet wird eine ganze Zahl ≥ 1"):
            Integer(minimum=1).validate("$weich", "k", self.settings)
        with self.assertRaisesRegex(ValueError, "k ist an das Setting anzahl \\(Slider\\) gebunden, erwartet wird eine ganze Zahl ≥ 5"):
            Integer(minimum=5).validate("$anzahl", "k", self.settings)
        with self.assertRaisesRegex(ValueError, "mode ist an das Setting modus \\(Auswahl\\) gebunden"):
            Choice("peak").validate("$modus", "mode", self.settings)

    def test_integer_parameters_need_whole_number_slider_steps(self):
        fractional = {"anteil": {**SLIDER, "name": "anteil", "control": {**SLIDER["control"], "step": 0.5}}}

        with self.assertRaisesRegex(ValueError, "Slider"):
            Integer(minimum=1).validate("$anteil", "k", fractional)

    def test_leaves_workflow_bindings_to_the_runtime(self):
        Integer(minimum=1).validate("$knoten.wert", "k", self.settings)
        Text().validate("$unbekannt", "voice", self.settings)


if __name__ == "__main__":
    unittest.main()
