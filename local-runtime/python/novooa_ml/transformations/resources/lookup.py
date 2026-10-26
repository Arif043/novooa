import json

from novooa_ml.transformations.kinds import DETECTIONS, JSON_RESULT, KEYPOINTS, SAME
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.schema import Choice, Text
from novooa_ml.transformations.strategy import TransformationStrategy


class ResourceLookupStrategy(TransformationStrategy):
    """Ergänzt Treffer um ihren Namen aus einer Label-Datei des Modells.

    Die Ressource (`artifactReference.resources`) ist eine Textdatei mit einem Label pro Zeile
    (`format: lines`) oder eine JSON-Liste von Texten. Für jeden Eintrag wird der Index aus `key`
    nachgeschlagen und als `field` ergänzt, z. B. nach `tensor.topK` ein `label`.
    """

    accepts = (JSON_RESULT, DETECTIONS, KEYPOINTS)
    produces = SAME
    parameters = {
        "resource": Text(),
        "format": Choice("lines", "json", optional=True, default="lines"),
        "key": Text(optional=True, default="index"),
        "field": Text(optional=True, default="label"),
    }

    @property
    def transformation_type(self):
        return "resource.lookup"

    def transform(self, value, parameters, context):
        name = parameters.get("resource")
        labels = labels_from(context.resource_bytes(name), parameters.get("format", "lines"), name)
        key, field = parameters.get("key", "index"), parameters.get("field", "label")
        if not isinstance(value, list):
            raise ValueError("resource.lookup erwartet eine Liste von Einträgen.")
        return [labeled(item, position, labels, key, field, name) for position, item in enumerate(value)]


def labels_from(data, data_format, name):
    text = data.decode("utf-8")
    if data_format == "lines":
        return text.splitlines()
    labels = json.loads(text)
    if not isinstance(labels, list) or not all(isinstance(label, str) for label in labels):
        raise ValueError(f"resource.lookup: Die Ressource {name} ist keine Liste von Texten.")
    return labels


def labeled(item, position, labels, key, field, name):
    index = item.get(key) if isinstance(item, dict) else None
    if not is_integer(index):
        raise ValueError(f"resource.lookup: Eintrag {position} hat keinen ganzzahligen Schlüssel {key}.")
    if not 0 <= index < len(labels):
        raise ValueError(
            f"resource.lookup: Der Index {index} liegt außerhalb der {len(labels)} Labels in {name}."
        )
    return {**item, field: labels[index]}
