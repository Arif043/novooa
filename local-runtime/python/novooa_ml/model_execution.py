from novooa_ml.model_output.worker import transform_outputs
from novooa_ml.tensor_codec import decode_tensor, encode_tensor


def runtime_dependencies():
    try:
        import numpy
        import onnxruntime
        return numpy, onnxruntime
    except ImportError as error:
        raise RuntimeError(
            "Der ML-Dienst benötigt numpy und onnxruntime. "
            "Installiere local-runtime/python/requirements.txt."
        ) from error


def session_factory(onnxruntime):
    # Laden über den Pfad: So findet ONNX Runtime ausgelagerte Gewichte (External Data) neben model.onnx.
    return lambda model_path: onnxruntime.InferenceSession(model_path, providers=["CPUExecutionProvider"])


def input_arrays(payload, numpy):
    return {tensor["name"]: decode_tensor(tensor, numpy) for tensor in payload["inputs"]}


def run_model(session, payload, numpy, resource_reader=None):
    names = [output["name"] for output in payload["outputs"]]
    values = session.run(names, input_arrays(payload, numpy))
    return transformed_output_tensors(payload, values, numpy, resource_reader)


def transformed_output_tensors(payload, values, numpy, resource_reader=None):
    named = zip([output["name"] for output in payload["outputs"]], values, strict=True)
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
