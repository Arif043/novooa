"""Workflow-Werte, die ein Script per `workflow_input("pfad")` liest.

Der Executor schickt nur die Werte mit, deren Pfad als fester Text im Script steht, jeweils
mit dem Typ, den der Wert im Workflow hat. Ein `datetime` kommt als `datetime` an, alles
andere so, wie JSON es liefert (str, int/float, bool, dict, list).
"""
from datetime import datetime


class WorkflowInputs:
    def __init__(self, inputs):
        self._inputs = inputs

    def read(self, name):
        if name not in self._inputs:
            raise LookupError(f'workflow_input("{name}"): Es gibt keinen Wert „{name}“.')
        entry = self._inputs[name]
        if entry.get("type") == "datetime":
            return datetime.fromisoformat(entry["value"])
        return entry.get("value")
