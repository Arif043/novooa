"""Fachliche Workflow-Ausgabewerte eines Scripts.

Das Script ruft `workflow_output(name, type, value)` auf; jeder Aufruf legt einen
benannten, typisierten Wert an, den nachfolgende Bausteine als `{{name}}` lesen.
Geprüft wird sofort beim Aufruf, damit ein Fehler die Zeile im Script trägt.
"""
import json
import math
from datetime import date, datetime

TYPES = ("string", "number", "boolean", "datetime", "json")


class WorkflowOutputs:
    def __init__(self):
        self._outputs = []

    def define(self, name, type, value):
        self._check_name(name)
        if type not in TYPES:
            raise ValueError(
                f'workflow_output("{name}"): unbekannter Typ {type!r}. Erlaubt: {", ".join(TYPES)}.'
            )
        self._outputs.append({"name": name, "type": type, "value": normalized(name, type, value)})

    def as_list(self):
        return list(self._outputs)

    def _check_name(self, name):
        if not isinstance(name, str) or not name.isidentifier():
            raise ValueError(
                f"workflow_output: Der Name {name!r} ist ungültig. Erlaubt sind Buchstaben, Ziffern und _, "
                "nicht am Anfang eine Ziffer."
            )
        if name == "value":
            raise ValueError('workflow_output: Der Name "value" ist reserviert.')
        if any(output["name"] == name for output in self._outputs):
            raise ValueError(f'workflow_output("{name}"): Der Name ist bereits vergeben.')


def normalized(name, type, value):
    check = _CHECKS[type]
    result = check(value)
    if result is _INVALID:
        raise TypeError(f'workflow_output("{name}"): erwartet {type}, erhalten {_type_name(value)}.')
    return result


_INVALID = object()


def _string(value):
    return value if isinstance(value, str) else _INVALID


def _number(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return _INVALID
    return value if math.isfinite(value) else _INVALID


def _boolean(value):
    return value if isinstance(value, bool) else _INVALID


def _datetime(value):
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, str):
        try:
            return datetime.fromisoformat(value).isoformat()
        except ValueError:
            return _INVALID
    return _INVALID


def _json(value):
    try:
        json.dumps(value, allow_nan=False)
    except (TypeError, ValueError):
        return _INVALID
    return value


_CHECKS = {
    "string": _string,
    "number": _number,
    "boolean": _boolean,
    "datetime": _datetime,
    "json": _json,
}


def _type_name(value):
    if value is None:
        return "None"
    return type(value).__name__
