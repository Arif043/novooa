"""Zusammengesetzte Schemas: Listen, Objekte mit festen Feldern, Zuordnungen und Alternativen."""

from .scalars import Schema, close_match


def child(path, key):
    return f"{path}.{key}" if path else str(key)


class ListOf(Schema):
    type_name = "list"

    def __init__(self, items, length=None, min_length=1, **options):
        super().__init__(**options)
        self.items, self.length, self.min_length = items, length, min_length

    def validate_value(self, value, path, settings):
        if not isinstance(value, list) or not self.fits(len(value)):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")
        for index, item in enumerate(value):
            self.items.validate(item, f"{path}[{index}]", settings)

    def fits(self, count):
        return count == self.length if self.length is not None else count >= self.min_length

    def expectation(self):
        count = self.length if self.length is not None else self.min_length
        noun = "Eintrag" if count == 1 else "Einträgen"
        return f"eine Liste mit {'genau' if self.length is not None else 'mindestens'} {count} {noun}"

    def details(self):
        details = {"items": self.items.describe()}
        if self.length is not None:
            details["length"] = self.length
        elif self.min_length != 1:
            details["minLength"] = self.min_length
        return details


class Record(Schema):
    """Objekt mit bekannten Feldern; unbekannte Felder sind ein Fehler (Schutz vor Tippfehlern)."""

    type_name = "record"

    def __init__(self, fields, **options):
        super().__init__(**options)
        self.fields = fields

    def validate_value(self, value, path, settings):
        if not isinstance(value, dict):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")
        for key in value:
            if key not in self.fields:
                raise ValueError(unknown_message(child(path, key), key, self.fields, path))
        for key, schema in self.fields.items():
            if key in value:
                schema.validate(value[key], child(path, key), settings)
            elif not schema.optional:
                raise ValueError(f"Der Parameter {child(path, key)} fehlt.")

    def expectation(self):
        return "ein Objekt"

    def details(self):
        return {"fields": {key: schema.describe() for key, schema in self.fields.items()}}


class MapOf(Schema):
    """Objekt mit beliebigen Schlüsseln, deren Werte alle einem Schema folgen."""

    type_name = "map"

    def __init__(self, values, **options):
        super().__init__(**options)
        self.values = values

    def validate_value(self, value, path, settings):
        if not isinstance(value, dict) or not value:
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")
        for key, item in value.items():
            self.values.validate(item, child(path, key), settings)

    def expectation(self):
        return "ein Objekt"

    def details(self):
        return {"values": self.values.describe()}


class OneOf(Schema):
    type_name = "oneOf"

    def __init__(self, *alternatives, **options):
        super().__init__(**options)
        self.alternatives = alternatives

    def validate_value(self, value, path, settings):
        if not any(alternative.accepts(value) for alternative in self.alternatives):
            raise ValueError(f"{path} erwartet {self.expectation()}, erhält {value!r}.")

    def expectation(self):
        return " oder ".join(alternative.expectation() for alternative in self.alternatives)

    def details(self):
        return {"alternatives": [alternative.describe() for alternative in self.alternatives]}


def unknown_message(full_name, key, fields, path):
    suggestion = close_match(key, fields)
    hint = f" — gemeint ist vermutlich {child(path, suggestion)}" if suggestion else ""
    return f"Unbekannter Parameter {full_name}{hint}."
