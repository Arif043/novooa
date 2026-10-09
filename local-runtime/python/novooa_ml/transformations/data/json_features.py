from numbers import Real

from novooa_ml.transformations.parameters import number

from novooa_ml.transformations.kinds import JSON, TENSOR
from novooa_ml.transformations.strategy import TransformationStrategy

KINDS = ("number", "boolean", "category")
MISSING = object()


class JsonFeaturesStrategy(TransformationStrategy):
    """Baut aus einem Datensatz (oder einer Liste davon) einen Merkmalsvektor in fester Reihenfolge.

    Jedes Merkmal liest ein Feld (Punktpfad wie `kunde.premium`) als Zahl, Wahrheitswert oder
    Kategorie (One-Hot). Zahlen lassen sich mit `mean`/`std` standardisieren; `default` ersetzt
    fehlende Felder.
    """

    accepts = (JSON,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "json.features"

    def transform(self, value, parameters, context):
        features = [feature_definition(item) for item in feature_list(parameters.get("features"))]
        records = value if isinstance(value, list) else [value]
        if not records or not all(isinstance(record, dict) for record in records):
            raise ValueError("json.features benötigt einen Datensatz oder eine Liste von Datensätzen.")
        rows = [row_for(record, features) for record in records]
        tensor = context.numpy.asarray(rows, dtype=context.numpy.float32)
        return tensor if isinstance(value, list) else tensor[0]


def feature_list(value):
    if not isinstance(value, list) or not value:
        raise ValueError("json.features benötigt eine nicht leere Liste features.")
    return value


def feature_definition(feature):
    if not isinstance(feature, dict) or not isinstance(feature.get("field"), str) or not feature["field"]:
        raise ValueError("json.features: Jedes Merkmal benötigt ein Feld field.")
    kind = feature.get("kind", "number")
    if kind not in KINDS:
        raise ValueError(f"json.features: kind muss einer der Werte {', '.join(KINDS)} sein.")
    std = feature.get("std", 1)
    if kind == "number" and number(std, "json.features", "std") == 0:
        raise ValueError(f"json.features: std des Merkmals {feature['field']} darf nicht null sein.")
    if kind == "category" and not valid_categories(feature.get("categories")):
        raise ValueError(f"json.features: Das Merkmal {feature['field']} benötigt eindeutige categories.")
    if feature.get("unknown", "zero") not in ("zero", "error"):
        raise ValueError("json.features: unknown muss zero oder error sein.")
    return {**feature, "kind": kind}


def valid_categories(categories):
    return isinstance(categories, list) and categories and len(set(map(repr, categories))) == len(categories)


def row_for(record, features):
    return [value for feature in features for value in encoded(record, feature)]


def encoded(record, feature):
    name = feature["field"]
    value = field_value(record, name)
    if value is MISSING:
        value = feature.get("default", MISSING)
    if value is MISSING:
        raise ValueError(f"json.features: Das Merkmal {name} fehlt im Datensatz.")
    kind = feature["kind"]
    if kind == "boolean":
        if not isinstance(value, bool):
            raise ValueError(f"json.features: Das Merkmal {name} ist kein Wahrheitswert.")
        return [1.0 if value else 0.0]
    if kind == "category":
        return one_hot(value, feature)
    if not isinstance(value, Real) or isinstance(value, bool):
        raise ValueError(f"json.features: Das Merkmal {name} ist keine Zahl.")
    return [(value - number(feature.get("mean", 0), "json.features", "mean")) / number(feature.get("std", 1), "json.features", "std")]


def one_hot(value, feature):
    categories = feature["categories"]
    if value not in categories and feature.get("unknown", "zero") == "error":
        raise ValueError(f"json.features: Das Merkmal {feature['field']} hat den unbekannten Wert {value}.")
    return [1.0 if value == category else 0.0 for category in categories]


def field_value(record, path):
    value = record
    for part in path.split("."):
        if not isinstance(value, dict) or part not in value:
            return MISSING
        value = value[part]
    return value
