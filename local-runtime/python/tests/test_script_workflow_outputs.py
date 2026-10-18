import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_script import execution


def run(script, variables=None):
    request = {"script": script, "variables": variables or {}, "files": []}
    return execution.execute(request, [])


class WorkflowOutputTest(unittest.TestCase):
    def test_defines_typed_outputs_in_call_order(self):
        result = run(
            "from datetime import datetime\n"
            "workflow_output('kunde', 'string', 'Müller')\n"
            "workflow_output('summe', 'number', 42.5)\n"
            "workflow_output('bezahlt', 'boolean', False)\n"
            "workflow_output('faellig', 'datetime', datetime(2026, 10, 1, 12, 30))\n"
            "workflow_output('rechnung', 'json', {'nr': 'R-1', 'positionen': [1, 2]})\n"
        )

        self.assertEqual(result["workflowOutputs"], [
            {"name": "kunde", "type": "string", "value": "Müller"},
            {"name": "summe", "type": "number", "value": 42.5},
            {"name": "bezahlt", "type": "boolean", "value": False},
            {"name": "faellig", "type": "datetime", "value": "2026-10-01T12:30:00"},
            {"name": "rechnung", "type": "json", "value": {"nr": "R-1", "positionen": [1, 2]}},
        ])

    def test_accepts_iso_text_for_datetime(self):
        result = run("workflow_output('faellig', 'datetime', '2026-10-01T08:00:00+02:00')")

        self.assertEqual(result["workflowOutputs"][0]["value"], "2026-10-01T08:00:00+02:00")

    def test_a_script_without_outputs_reports_an_empty_list(self):
        self.assertEqual(run("output = 'x'")["workflowOutputs"], [])

    def test_the_function_is_not_passed_on_as_a_variable(self):
        result = run("workflow_output('a', 'number', 1)\nzahl = 2")

        self.assertEqual(result["variables"], {"zahl": 2})

    def test_a_wrong_type_fails_with_the_line_of_the_call(self):
        with self.assertRaisesRegex(execution.ScriptFailed, r'Zeile 2: TypeError: workflow_output\("summe"\): erwartet number, erhalten str'):
            run("x = 1\nworkflow_output('summe', 'number', '42')")

    def test_booleans_are_not_numbers(self):
        with self.assertRaisesRegex(execution.ScriptFailed, "erwartet number, erhalten bool"):
            run("workflow_output('summe', 'number', True)")

    def test_rejects_non_finite_numbers_and_invalid_dates(self):
        with self.assertRaisesRegex(execution.ScriptFailed, "erwartet number"):
            run("workflow_output('summe', 'number', float('nan'))")
        with self.assertRaisesRegex(execution.ScriptFailed, "erwartet datetime"):
            run("workflow_output('faellig', 'datetime', 'morgen')")

    def test_rejects_values_that_are_not_json(self):
        with self.assertRaisesRegex(execution.ScriptFailed, "erwartet json, erhalten set"):
            run("workflow_output('daten', 'json', {1, 2})")

    def test_rejects_unknown_types_invalid_and_duplicate_names(self):
        with self.assertRaisesRegex(execution.ScriptFailed, "unbekannter Typ 'datum'"):
            run("workflow_output('faellig', 'datum', '2026-10-01')")
        with self.assertRaisesRegex(execution.ScriptFailed, "Der Name '2fach' ist ungültig"):
            run("workflow_output('2fach', 'number', 2)")
        with self.assertRaisesRegex(execution.ScriptFailed, '"value" ist reserviert'):
            run("workflow_output('value', 'number', 2)")
        with self.assertRaisesRegex(execution.ScriptFailed, r'Zeile 2: .*"summe"\): Der Name ist bereits vergeben'):
            run("workflow_output('summe', 'number', 1)\nworkflow_output('summe', 'number', 2)")

    def test_a_variable_with_the_same_name_does_not_hide_the_function(self):
        result = run("workflow_output('a', 'number', 1)", variables={"workflow_output": "alt"})

        self.assertEqual(result["workflowOutputs"][0]["name"], "a")


if __name__ == "__main__":
    unittest.main()
