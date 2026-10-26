"""Findet die Modellausgänge, die Transformationen eines Vertrags über Parameter lesen."""

from .schema import ListOf, OutputName


def referenced_outputs(contract, registry):
    """Namen aus Parametern vom Schema `OutputName` (auch als Liste), samt Ort für Meldungen."""
    references = []
    for definition in [*contract.get("inputs", []), *contract.get("outputs", [])]:
        for transformation in definition.get("transformations", []):
            schemas = registry.parameters_of(transformation.get("type")) or {}
            for name, schema in schemas.items():
                for output in names_of(schema, transformation.get("parameters", {}).get(name)):
                    references.append((output, f"{definition['name']}: {transformation['type']}.{name}"))
    return references


def names_of(schema, value):
    if isinstance(schema, OutputName) and isinstance(value, str):
        return [value]
    if isinstance(schema, ListOf) and isinstance(schema.items, OutputName) and isinstance(value, list):
        return [item for item in value if isinstance(item, str)]
    return []
