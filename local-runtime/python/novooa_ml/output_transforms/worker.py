from novooa_ml.transformations.context import TransformationContext

from .default_registry import default_output_transformation_registry


def transform_outputs(outputs, definitions, output_parameters, numpy, resource_reader=None):
    by_name = {definition["name"]: definition for definition in definitions}
    registry = default_output_transformation_registry()
    return [
        {
            "name": name,
            "tensor": tensor,
            "transformationValues": transformation_values(
                registry, tensor, by_name[name].get("transformations", []),
                TransformationContext(
                    numpy, resource_reader=resource_reader,
                    output_name=name, output_parameters=output_parameters,
                ),
            ),
        }
        for name, tensor in outputs
    ]


def transformation_values(registry, tensor, transformations, context):
    """`tensor` ist der Endwert der Pipeline, dazu jedes per `result` benannte Zwischenergebnis."""
    result = registry.run(tensor, transformations, context)
    values = {name: workflow_value(value) for name, value in result.results.items()}
    return {**values, "tensor": workflow_value(result.value)}


def workflow_value(value):
    if hasattr(value, "tolist"):
        return value.tolist()
    return value
