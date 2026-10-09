from novooa_ml.transformations.discovery import strategy_instances
from novooa_ml.transformations.registry import TransformationRegistry


def default_output_transformation_registry():
    """Ausgangstransformationen plus die in beiden Richtungen geteilten Tensoroperationen."""
    return TransformationRegistry(
        strategy_instances("novooa_ml.output_transforms", "novooa_ml.transformations.shared")
    )
