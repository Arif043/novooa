from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.pipeline_check import check_output_pipeline


def transform_outputs(outputs, definitions, numpy, resource_reader=None):
    by_name = {definition["name"]: definition for definition in definitions}
    registry = default_transformation_registry()
    # `outputs` kann ein einmal lesbarer Iterator sein (zip im ONNX-Worker).
    outputs = [(name, *dense_output(name, value, numpy)) for name, value in outputs]
    for name, _, _ in outputs:
        check_output_pipeline(name, by_name[name].get("transformations", []), registry)
    return [
        {
            "name": name,
            "tensor": tensor,
            "transformationValues": {**extras, **transformation_values(
                registry, tensor, by_name[name].get("transformations", []),
                TransformationContext(numpy, resource_reader=resource_reader),
            )},
        }
        for name, tensor, extras in outputs
    ]


def dense_output(name, value, numpy):
    """Macht ZipMap-Ausgänge (Liste von {Klasse: Wahrscheinlichkeit}) zu einem dichten Tensor.

    scikit-learn-Klassifikatoren liefern Wahrscheinlichkeiten über `skl2onnx` standardmäßig so.
    Die Spalten folgen der Klassenreihenfolge; die Klassen stehen als `classes` bereit.
    """
    if not isinstance(value, list) or not value or not all(isinstance(row, dict) for row in value):
        return value, {}
    classes = list(value[0].keys())
    if any(list(row.keys()) != classes for row in value):
        raise ValueError(f"Ausgang {name}: Die Klassen der Einträge unterscheiden sich.")
    dense = numpy.asarray([[row[key] for key in classes] for row in value], dtype=numpy.float32)
    return dense, {"classes": classes}


def transformation_values(registry, tensor, transformations, context):
    """`tensor` ist der Endwert der Pipeline, dazu jedes per `result` benannte Zwischenergebnis."""
    result = registry.run(tensor, transformations, context)
    values = {name: workflow_value(value) for name, value in result.results.items()}
    return {**values, "tensor": workflow_value(result.value)}


def workflow_value(value):
    if hasattr(value, "tolist"):
        return value.tolist()
    return value
