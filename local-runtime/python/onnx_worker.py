import base64
import json
import sys

from novooa_ml.model_output.worker import transform_outputs
from novooa_ml.tensor_codec import decode_tensor, encode_tensor


def runtime_dependencies():
    try:
        import numpy
        import onnxruntime
        return numpy, onnxruntime
    except ImportError as error:
        raise RuntimeError(
            "Die lokale ONNX-Runtime benötigt numpy und onnxruntime. "
            "Installiere local-runtime/python/requirements.txt."
        ) from error


def input_arrays(payload, numpy):
    return {tensor["name"]: decode_tensor(tensor, numpy) for tensor in payload["inputs"]}


def execute(payload, numpy, onnxruntime):
    model_bytes = base64.b64decode(payload["modelBase64"], validate=True)
    session = onnxruntime.InferenceSession(
        model_bytes, providers=["CPUExecutionProvider"]
    )
    values = session.run([output["name"] for output in payload["outputs"]], input_arrays(payload, numpy))
    return {"outputs": transformed_output_tensors(payload, values, numpy)}


def transformed_output_tensors(payload, values, numpy, resource_reader=None):
    named = zip(
        [output["name"] for output in payload["outputs"]],
        values,
        strict=True,
    )
    # Eingänge tragen z. B. ihre Bildgeometrie, damit Ausgänge ins Originalbild zurückrechnen.
    input_metadata = {tensor["name"]: tensor.get("metadata", {}) for tensor in payload.get("inputs", [])}
    transformed = transform_outputs(named, payload["outputs"], numpy, resource_reader, input_metadata)
    return [
        {
            **encode_tensor(output["name"], output["tensor"], numpy),
            "transformationValues": output["transformationValues"],
        }
        for output in transformed
    ]

def main():
    payload = json.loads(sys.stdin.read())
    numpy, onnxruntime = runtime_dependencies()
    sys.stdout.write(json.dumps(execute(payload, numpy, onnxruntime)))


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        sys.stderr.write(str(error))
        sys.exit(1)
