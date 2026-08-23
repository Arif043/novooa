import json
import sys


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


def model_types():
    return {
        "float32": "tensor(float)", "float64": "tensor(double)",
        "int64": "tensor(int64)", "int32": "tensor(int32)",
        "int16": "tensor(int16)", "int8": "tensor(int8)",
        "uint8": "tensor(uint8)", "bool": "tensor(bool)",
    }


def validate_definition(definition, node, kind):
    if definition["name"] != node.name:
        raise ValueError(f"Der {kind}-Tensor {definition['name']} fehlt im ONNX-Modell.")
    if model_types()[definition["dataType"]] != node.type:
        raise ValueError(f"Der Datentyp von {definition['name']} stimmt nicht mit dem ONNX-Modell überein.")
    validate_shape(definition["shape"], node.shape, definition["name"])


def validate_shape(expected, actual, name):
    if len(expected) != len(actual):
        raise ValueError(f"Die Tensor-Form von {name} stimmt nicht mit dem ONNX-Modell überein.")
    for expected_dimension, actual_dimension in zip(expected, actual, strict=True):
        if expected_dimension != "dynamic" and expected_dimension != actual_dimension:
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


def validate(payload):
    session = session_for(payload, runtime())
    validate_inputs(payload["contract"], session)
    validate_outputs(payload["contract"], session)
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
