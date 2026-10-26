import json
import sys
from pathlib import Path

# `python -I` nimmt das Skriptverzeichnis nicht in den Suchpfad auf; ohne es fehlt `novooa_ml`.
sys.path.insert(0, str(Path(__file__).resolve().parent))

ONNX_TYPES = {
    "float32": "tensor(float)", "float16": "tensor(float16)", "float64": "tensor(double)",
    "int64": "tensor(int64)", "int32": "tensor(int32)",
    "int16": "tensor(int16)", "int8": "tensor(int8)",
    "uint8": "tensor(uint8)", "bool": "tensor(bool)", "string": "tensor(string)",
}
# ZipMap-Ausgänge (skl2onnx) macht der Ausgabe-Worker zu einem dichten float32-Tensor.
ZIPMAP_TYPE_PREFIX = "seq(map("


def runtime():
    try:
        import onnxruntime
        return onnxruntime
    except ImportError as error:
        raise RuntimeError(
            "Die Modellprüfung benötigt onnxruntime. "
            "Installiere local-runtime/python/requirements.txt."
        ) from error


def session_for(payload, onnxruntime):
    return onnxruntime.InferenceSession(
        payload["artifactPath"], providers=["CPUExecutionProvider"]
    )


def validate_definition(definition, node, kind):
    if is_zipmap(definition, node):
        return
    if ONNX_TYPES.get(definition["dataType"]) != node.type:
        raise ValueError(
            f"Der Datentyp von {definition['name']} stimmt nicht mit dem ONNX-Modell überein "
            f"(Vertrag {definition['dataType']}, Modell {node.type})."
        )
    validate_shape(definition["shape"], node.shape, definition["name"])


def is_zipmap(definition, node):
    return definition["dataType"] == "float32" and node.type.startswith(ZIPMAP_TYPE_PREFIX)


def validate_shape(expected, actual, name):
    if len(expected) != len(actual):
        raise ValueError(f"Die Tensor-Form von {name} stimmt nicht mit dem ONNX-Modell überein.")
    for expected_dimension, actual_dimension in zip(expected, actual, strict=True):
        # Dynamische Achsen des Modells (None oder symbolisch) nehmen jede Größe an.
        if not isinstance(actual_dimension, int) or expected_dimension == "dynamic":
            continue
        if expected_dimension != actual_dimension:
            raise ValueError(f"Die Tensor-Form von {name} stimmt nicht mit dem ONNX-Modell überein.")


def validate_inputs(contract, session):
    nodes = {node.name: node for node in session.get_inputs()}
    if len(nodes) != len(contract["inputs"]):
        raise ValueError("Der Modellvertrag beschreibt nicht alle ONNX-Eingänge.")
    for definition in contract["inputs"]:
        validate_definition(definition, required_node(nodes, definition, "Eingangs"), "Eingangs")


def validate_outputs(contract, session):
    nodes = {node.name: node for node in session.get_outputs()}
    for definition in contract["outputs"]:
        validate_definition(definition, required_node(nodes, definition, "Ausgangs"), "Ausgangs")


def required_node(nodes, definition, kind):
    node = nodes.get(definition["name"])
    if node is None:
        raise ValueError(f"Der {kind}-Tensor {definition['name']} fehlt im ONNX-Modell.")
    return node


def validate_referenced_outputs(contract, session):
    """Transformationen dürfen Hilfsausgänge lesen (`OutputName`); die müssen im Modell existieren."""
    from novooa_ml.transformations.default_registry import default_transformation_registry
    from novooa_ml.transformations.output_references import referenced_outputs

    names = {node.name for node in session.get_outputs()}
    for output, place in referenced_outputs(contract, default_transformation_registry()):
        if output not in names:
            raise ValueError(f"{place} nennt den Ausgang {output}, den das ONNX-Modell nicht hat.")


def validate(payload):
    session = session_for(payload, runtime())
    validate_inputs(payload["contract"], session)
    validate_outputs(payload["contract"], session)
    validate_referenced_outputs(payload["contract"], session)
    return {"valid": True}


def main():
    payload = json.loads(sys.stdin.read())
    sys.stdout.write(json.dumps(validate(payload)))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        sys.stderr.write(f"Die ONNX-Modellprüfung ist fehlgeschlagen: {error}")
        sys.exit(1)
