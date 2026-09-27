from .registry import TransformationRegistry
from .strategy import InputTransformStrategy
from novooa_ml.transformation_discovery import strategy_instances


def default_transformation_registry():
    return TransformationRegistry(
        strategy_instances("novooa_ml.input_transforms", InputTransformStrategy)
    )
