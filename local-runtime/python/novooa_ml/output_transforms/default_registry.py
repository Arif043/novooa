from .registry import OutputTransformationRegistry, OutputTransformationStrategy
from novooa_ml.transformation_discovery import strategy_instances


def default_output_transformation_registry():
    return OutputTransformationRegistry(
        strategy_instances("novooa_ml.output_transforms", OutputTransformationStrategy)
    )
