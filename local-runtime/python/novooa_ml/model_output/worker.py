from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.pipeline_check import check_output_pipeline


def transform_outputs(outputs, definitions, output_parameters, numpy, resource_reader=None):
    by_name = {definition["name"]: definition for definition in definitions}
    registry = default_transformation_registry()
    # `outputs` kann ein einmal lesbarer Iterator sein (zip im ONNX-Worker).
    outputs = list(outputs)
    for name, _ in outputs:
        check_output_pipeline(name, by_name[name].get("transformations", []), registry)
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
