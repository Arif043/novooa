import base64
import json
import sys

from novooa_ml.output_transforms.worker import transform_outputs


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
    return {
        tensor["name"]: array_from_tensor(tensor, numpy)
        for tensor in payload["inputs"]
    }


def array_from_tensor(tensor, numpy):
    data_type = numpy_data_type(tensor["dataType"], numpy)
    data = base64.b64decode(tensor["dataBase64"], validate=True)
    return numpy.frombuffer(data, dtype=data_type).reshape(tensor["shape"])


def numpy_data_type(name, numpy):
    data_types = {
        "float32": numpy.float32,
        "float64": numpy.float64,
        "int64": numpy.int64,
        "int32": numpy.int32,
        "int16": numpy.int16,
        "int8": numpy.int8,
        "uint8": numpy.uint8,
        "bool": numpy.bool_,
    }
    if name not in data_types:
        raise ValueError(f"Nicht unterstützter Tensor-Datentyp: {name}")
    return data_types[name]


def tensor_for_output(name, array, numpy):
    normalized = numpy.ascontiguousarray(array)
    return {
        "name": name,
        "dataType": model_data_type(normalized.dtype, numpy),
        "shape": list(normalized.shape),
        "dataBase64": base64.b64encode(normalized.tobytes()).decode("ascii"),
    }


def model_data_type(data_type, numpy):
    data_types = {
        numpy.dtype(numpy.float32): "float32",
        numpy.dtype(numpy.float64): "float64",
        numpy.dtype(numpy.int64): "int64",
        numpy.dtype(numpy.int32): "int32",
        numpy.dtype(numpy.int16): "int16",
        numpy.dtype(numpy.int8): "int8",
        numpy.dtype(numpy.uint8): "uint8",
        numpy.dtype(numpy.bool_): "bool",
    }
    if data_type not in data_types:
        raise ValueError(f"Nicht unterstützter ONNX-Ausgabe-Datentyp: {data_type}")
    return data_types[data_type]


def execute(payload, numpy, onnxruntime):
    model_bytes = base64.b64decode(payload["modelBase64"], validate=True)
    session = onnxruntime.InferenceSession(
        model_bytes, providers=["CPUExecutionProvider"]
    )
    values = session.run([output["name"] for output in payload["outputs"]], input_arrays(payload, numpy))
    return {"outputs": transformed_output_tensors(payload, values, numpy)}


def transformed_output_tensors(payload, values, numpy):
    named = zip(
        [output["name"] for output in payload["outputs"]],
        values,
        strict=True,
    )
    transformed = transform_outputs(named, payload["outputs"], payload.get("outputParameters", []), numpy)
    return [
        {
            **tensor_for_output(output["name"], output["tensor"], numpy),
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
