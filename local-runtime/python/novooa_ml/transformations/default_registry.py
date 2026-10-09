from .discovery import strategy_instances
from .registry import TransformationRegistry


def default_transformation_registry():
    """Alle Transformationen in einem Katalog; die Richtung ergibt sich aus der Pipeline."""
    return TransformationRegistry(strategy_instances("novooa_ml.transformations"))
