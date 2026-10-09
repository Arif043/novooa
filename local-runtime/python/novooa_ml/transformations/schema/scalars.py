"""Einfache Parameterschemas: Zahlen, Wahrheitswerte, Texte, Auswahl.

Die gemeinsame Basis `Schema` prüft auch Bindungen `"$name"` an Settings des Vertrags.
"""

import re
from difflib import get_close_matches
from numbers import Real

BINDING = re.compile(r"^\$([A-Za-z_]\w*)((?:\.[A-Za-z_]\w*|\.\d+)*)$")
CONTROL_LABELS = {"slider": "Slider", "checkbox": "Checkbox", "radioGroup": "Auswahl"}


class Schema:
    type_name = "any"

    def __init__(self, optional=False, default=None):
        self.optional = optional
        self.default = default

    def validate(self, value, path, settings=None):
        """Prüft einen Wert; eine Bindung `"$name"` an ein Setting prüft dessen Steuerelement."""
        setting = bound_setting(value, settings)
        if setting is not None:
            return self.validate_binding(setting, path)
        if is_binding(value):
            return None  # Bindung an einen Workflow-Wert: erst zur Laufzeit bekannt.
        return self.validate_value(value, path, settings)

    def validate_value(self, value, path, settings):
        """Die Basis nimmt jeden Wert an; Unterklassen schränken ein."""

    def accepts(self, value):
        try:
            self.validate_value(value, "", None)
            return True
        except ValueError:
            return False

    def validate_binding(self, setting, path):
        control = setting["control"]
        if all(self.accepts(normalized(value)) for value in setting_values(control)) and self.accepts_control(control):
            return
        label = CONTROL_LABELS.get(control.get("type"), control.get("type"))
        raise ValueError(
            f"{path} ist an das Setting {setting['name']} ({label}) gebunden, "
            f"erwartet wird {self.expectation()}."
        )

    def accepts_control(self, control):
        return True

    def expectation(self):
        return "einen Wert"

    def describe(self):
        description = {"type": self.type_name, "optional": self.optional}
        if self.default is not None:
            description["default"] = self.default
        return {**description, **self.details()}

    def details(self):
        return {}


class Integer(Schema):
    type_name = "integer"

    def __init__(self, minimum=None, maximum=None, **options):
        super().__init__(**options)
        self.minimum, self.maximum = minimum, maximum

    def validate_value(self, value, path, settings):
        whole = isinstance(value, int) and not isinstance(value, bool)
        if not whole or not within(value, self.minimum, self.maximum):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")

    def accepts_control(self, control):
        step = control.get("step")
        return control.get("type") != "slider" or (isinstance(step, Real) and float(step).is_integer())

    def expectation(self):
        return "eine ganze Zahl" + bounds(self.minimum, self.maximum)

    def details(self):
        return without_none({"minimum": self.minimum, "maximum": self.maximum})


class Number(Integer):
    type_name = "number"

    def validate_value(self, value, path, settings):
        numeric = isinstance(value, Real) and not isinstance(value, bool)
        if not numeric or not within(value, self.minimum, self.maximum):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")

    def accepts_control(self, control):
        return True

    def expectation(self):
        return "eine Zahl" + bounds(self.minimum, self.maximum)


class Boolean(Schema):
    type_name = "boolean"

    def validate_value(self, value, path, settings):
        if not isinstance(value, bool):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")

    def expectation(self):
        return "einen Wahrheitswert"


class Text(Schema):
    type_name = "text"

    def __init__(self, allow_empty=False, **options):
        super().__init__(**options)
        self.allow_empty = allow_empty

    def validate_value(self, value, path, settings):
        if not isinstance(value, str) or (not value and not self.allow_empty):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")

    def expectation(self):
        return "einen Text" if self.allow_empty else "einen nicht leeren Text"


class Choice(Schema):
    type_name = "choice"

    def __init__(self, *options, **settings):
        super().__init__(**settings)
        self.options = options

    def validate_value(self, value, path, settings):
        # Typgleichheit verhindert, dass 1 und True als derselbe Wert gelten.
        if not any(value == option and type(value) is type(option) for option in self.options):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")

    def expectation(self):
        return "einen der Werte " + ", ".join(str(option) for option in self.options)

    def details(self):
        return {"options": list(self.options)}


def within(value, minimum, maximum):
    return (minimum is None or value >= minimum) and (maximum is None or value <= maximum)


def bounds(minimum, maximum):
    if minimum is not None and maximum is not None:
        return f" zwischen {minimum} und {maximum}"
    if minimum is not None:
        return f" ≥ {minimum}"
    return "" if maximum is None else f" ≤ {maximum}"


def without_none(values):
    return {key: value for key, value in values.items() if value is not None}


def is_binding(value):
    return isinstance(value, str) and BINDING.match(value) is not None


def bound_setting(value, settings):
    match = BINDING.match(value) if isinstance(value, str) else None
    if match is None or match.group(2) or not settings:
        return None
    return settings.get(match.group(1))


def setting_values(control):
    kind = control.get("type")
    if kind == "slider":
        return [control.get("initial"), control.get("minimum"), control.get("maximum")]
    if kind == "checkbox":
        return [True, False]
    return [option.get("value") for option in control.get("options", [])]


def normalized(value):
    # Settings kommen als JSON; 3.0 und 3 sind dort derselbe Wert.
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return value


def close_match(name, candidates):
    matches = get_close_matches(name, list(candidates), n=1, cutoff=0.6)
    return matches[0] if matches else None

