from .transformations.default_registry import default_transformation_registry
from .transformations.pipeline_check import check_contract


def transformation_capabilities():
    """Alle Transformationen samt Wertarten.

    Jede Transformation ist in beiden Richtungen erlaubt, sofern die Wertarten der Pipeline
    passen; die beiden Typlisten bleiben für bestehende Clients erhalten.
    """
    registry = default_transformation_registry()
    types = registry.supported_types
    return {
        "inputTransformationTypes": types,
        "outputTransformationTypes": types,
        "kinds": {
            transformation_type: dict(zip(("accepts", "produces"), registry.kinds_of(transformation_type)))
            for transformation_type in types
        },
        "parameters": {
            transformation_type: {
                name: schema.describe() for name, schema in registry.parameters_of(transformation_type).items()
            }
            for transformation_type in types
        },
    }


def validate_contract(payload):
    """Prüft alle Pipelines eines Modellvertrags, bevor das Modell installiert wird."""
    contract = payload.get("contract") if isinstance(payload, dict) else None
    if not isinstance(contract, dict):
        raise ValueError("Der Modellvertrag fehlt.")
    check_contract(contract, default_transformation_registry())
    return {"status": "ok"}
