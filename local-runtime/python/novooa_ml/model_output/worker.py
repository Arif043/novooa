from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.pipeline_check import check_output_pipeline


def transform_outputs(outputs, definitions, numpy, resource_reader=None, input_metadata=None):
    """Transformiert die Ausgänge des Vertrags; alle Rohausgänge stehen den Pipelines zur Verfügung.

    `outputs`: Rohausgänge des Modells als Zuordnung oder Paare (Name, Wert). Hilfsausgänge ohne
    eigene Definition werden nur gelesen, z. B. Scores zu den Boxen eines anderen Ausgangs.
    """
    registry = default_transformation_registry()
    # `outputs` kann ein einmal lesbarer Iterator sein (zip im ONNX-Worker).
    dense = {name: dense_output(name, value, numpy) for name, value in dict(outputs).items()}
    raw = {name: tensor for name, (tensor, _) in dense.items()}
    for definition in definitions:
        if definition["name"] not in dense:
            raise ValueError(f"Das Modell hat keinen Ausgang {definition['name']}.")
        check_output_pipeline(definition["name"], definition.get("transformations", []), registry)
    return [output_result(definition, dense, raw, registry, numpy, resource_reader, input_metadata) for definition in definitions]


def output_result(definition, dense, raw, registry, numpy, resource_reader, input_metadata):
    name = definition["name"]
    tensor, extras = dense[name]
    context = TransformationContext(
        numpy, image_module=image_module(), resource_reader=resource_reader, inputs=input_metadata, outputs=raw,
    )
    values = transformation_values(registry, tensor, definition.get("transformations", []), context)
    return {"name": name, "tensor": tensor, "transformationValues": {**extras, **values}}


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


def image_module():
    """Pillow für Bildausgaben (`image.encode`); ohne Pillow bleiben andere Ausgänge nutzbar."""
    try:
        from PIL import Image
    except ImportError:
        return None
    return Image
