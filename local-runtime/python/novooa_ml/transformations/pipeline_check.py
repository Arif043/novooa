"""Prüft, ob die Wertarten einer Pipeline zusammenpassen — beim Import und vor jedem Lauf."""

from .kinds import SOURCE_KINDS, TENSOR, accepts, is_tensor_ready


def check_input_pipeline(name, source_type, transformations, registry):
    """Eingang: beginnt mit der Art der Quelle und muss einen Tensor ergeben."""
    label = f"Eingang {name}"
    start = SOURCE_KINDS.get(source_type)
    if start is None:
        raise ValueError(f"{label}: Die Quelle {source_type} wird nicht unterstützt.")
    kind = walk(label, start, transformations, registry)
    if not is_tensor_ready(kind):
        raise ValueError(f"{label}: Die Transformationen müssen einen Tensor erzeugen, enden aber bei {kind}.")


def check_output_pipeline(name, transformations, registry):
    """Ausgang: beginnt beim Modelltensor und darf mit jeder Wertart enden."""
    walk(f"Ausgang {name}", TENSOR, transformations, registry)


def check_contract(contract, registry):
    for definition in contract.get("inputs", []):
        check_contract_input(definition, registry)
    for definition in contract.get("outputs", []):
        check_output_pipeline(definition["name"], definition.get("transformations", []), registry)


def check_contract_input(definition, registry):
    transformations = definition.get("transformations", [])
    # Tensor-Quellen gehen unverändert ans Modell; Transformationen dafür lehnt die Runtime ab.
    if definition.get("source") == "tensor":
        if transformations:
            raise ValueError(f"Eingang {definition['name']}: Tensor-Quellen erlauben keine Transformationen.")
        return
    check_input_pipeline(definition["name"], definition.get("source"), transformations, registry)


def walk(label, kind, transformations, registry):
    for transformation in transformations:
        transformation_type = transformation.get("type")
        kinds = registry.kinds_of(transformation_type)
        if kinds is None:
            raise ValueError(f"{label}: Nicht unterstützte Transformation: {transformation_type}")
        accepted, produced = kinds
        if not accepts(accepted, kind):
            raise ValueError(
                f"{label}: {transformation_type} erwartet {' oder '.join(accepted)}, erhält {kind}."
            )
        kind = produced
    return kind
