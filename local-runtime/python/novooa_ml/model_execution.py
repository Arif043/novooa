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


def session_factory(onnxruntime, intra_op_threads=None):
    """Laden über den Pfad: So findet ONNX Runtime ausgelagerte Gewichte (External Data) neben model.onnx."""
    options = onnxruntime.SessionOptions()
    if intra_op_threads is not None:
        # Jede Rechnung bekommt einen festen Anteil der Kerne; die Warteschlange begrenzt, wie viele parallel laufen.
        options.intra_op_num_threads = intra_op_threads
        options.inter_op_num_threads = 1
    return lambda model_path: onnxruntime.InferenceSession(model_path, options, providers=["CPUExecutionProvider"])


def input_arrays(payload, numpy):
    return {tensor["name"]: decode_tensor(tensor, numpy) for tensor in payload["inputs"]}


def run_model(session, payload, numpy, resource_reader=None):
    # Alle Ausgänge: Pipelines dürfen Hilfsausgänge lesen, die keinen eigenen Vertragsausgang haben.
    names = [output.name for output in session.get_outputs()]
    raw = dict(zip(names, session.run(names, input_arrays(payload, numpy)), strict=True))
    missing = [output["name"] for output in payload["outputs"] if output["name"] not in raw]
    if missing:
        raise ValueError(f"Das Modell hat keinen Ausgang {missing[0]}.")
    return transformed_output_tensors(payload, raw, numpy, resource_reader)


def transformed_output_tensors(payload, raw_outputs, numpy, resource_reader=None):
    """`raw_outputs`: alle Rohausgänge (Name → Wert) oder Werte in der Reihenfolge der Vertragsausgänge."""
    if not isinstance(raw_outputs, dict):
        raw_outputs = dict(zip([output["name"] for output in payload["outputs"]], raw_outputs, strict=True))
    # Eingänge tragen z. B. ihre Bildgeometrie, damit Ausgänge ins Originalbild zurückrechnen.
    input_metadata = {tensor["name"]: tensor.get("metadata", {}) for tensor in payload.get("inputs", [])}
    transformed = transform_outputs(raw_outputs, payload["outputs"], numpy, resource_reader, input_metadata)
    return [
        {
            **encode_tensor(output["name"], output["tensor"], numpy),
            "transformationValues": output["transformationValues"],
        }
        for output in transformed
    ]
