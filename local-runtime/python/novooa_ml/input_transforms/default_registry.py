from novooa_ml.transformations.discovery import strategy_instances
from novooa_ml.transformations.registry import TransformationRegistry


def default_transformation_registry():
    """Eingangstransformationen plus die in beiden Richtungen geteilten Tensoroperationen."""
    return TransformationRegistry(
        strategy_instances("novooa_ml.input_transforms", "novooa_ml.transformations.shared")
    )
