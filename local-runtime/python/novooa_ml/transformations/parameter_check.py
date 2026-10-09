"""Prüft die Parameter jeder Transformation eines Vertrags gegen ihr Schema."""

from .schema import Record


def check_parameters(label, transformation, schema, settings):
    """Fehlende, falsche und unbekannte Parameter sowie unpassende Setting-Bindungen."""
    transformation_type = transformation.get("type")
    parameters = transformation.get("parameters", {})
    try:
        Record(schema).validate(parameters, "", settings)
    except ValueError as error:
        raise ValueError(f"{label}: {transformation_type}: {error}") from None


def settings_by_name(contract):
    return {setting["name"]: setting for setting in contract.get("settings") or [] if isinstance(setting, dict)}
