from .default_registry import default_output_transformation_registry
from .registry import OutputTransformationContext


def transform_outputs(outputs, definitions, output_parameters, numpy):
    by_name = {definition["name"]: definition for definition in definitions}
    registry = default_output_transformation_registry()
    return [
        {
            "name": name,
            "tensor": tensor,
            "transformationValues": registry.process(
                tensor,
                by_name[name].get("transformations", []),
                OutputTransformationContext(name, output_parameters, numpy),
            ),
        }
        for name, tensor in outputs
    ]
