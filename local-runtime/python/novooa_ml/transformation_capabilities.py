from .input_transforms.default_registry import default_transformation_registry
from .output_transforms.default_registry import default_output_transformation_registry


def transformation_capabilities():
    return {
        "inputTransformationTypes": default_transformation_registry().supported_types,
        "outputTransformationTypes": default_output_transformation_registry().supported_types,
    }
