"""Kodierung von Tensoren an der Grenze zwischen TypeScript und Python.

Zahlentensoren reisen als Base64 ihrer Little-Endian-Bytes. String-Tensoren (z. B. Text-
Klassen oder Kategoriespalten klassischer ML-Modelle) reisen als Base64 eines UTF-8-JSON-
Arrays ihrer Werte in Zeilenfolge; numpy hält sie als `object`-Array.
"""

import base64
import json

STRING = "string"
NUMERIC_TYPES = ("float32", "float16", "float64", "int64", "int32", "int16", "int8", "uint8", "bool")


def numpy_data_type(name, numpy):
    if name == STRING:
        return object
    if name not in NUMERIC_TYPES:
        raise ValueError(f"Nicht unterstützter Tensor-Datentyp: {name}")
    return numpy.bool_ if name == "bool" else getattr(numpy, name)


def model_data_type(dtype, numpy):
    if dtype.kind in "OUS":
        return STRING
    name = "bool" if dtype == numpy.bool_ else dtype.name
    if name not in NUMERIC_TYPES:
        raise ValueError(f"Nicht unterstützter Tensor-Datentyp: {name}")
    return name


def encode_tensor(name, array, numpy):
    array = numpy.asarray(array)
    data_type = model_data_type(array.dtype, numpy)
    if data_type == STRING:
        data = json.dumps([text_of(name, value) for value in array.reshape(-1).tolist()], ensure_ascii=False).encode("utf-8")
    else:
        data = numpy.ascontiguousarray(array).astype(array.dtype.newbyteorder("<")).tobytes()
    return {
        "name": name,
        "dataType": data_type,
        "shape": list(array.shape),
        "dataBase64": base64.b64encode(data).decode("ascii"),
    }


def decode_tensor(tensor, numpy):
    data = base64.b64decode(tensor["dataBase64"], validate=True)
    shape = tensor["shape"]
    if tensor["dataType"] != STRING:
        return numpy.frombuffer(data, dtype=numpy_data_type(tensor["dataType"], numpy)).reshape(shape)
    values = json.loads(data.decode("utf-8"))
    if not isinstance(values, list) or len(values) != int(numpy.prod(shape)) or not all(isinstance(v, str) for v in values):
        raise ValueError(f"Der String-Tensor {tensor['name']} passt nicht zu seiner Form {shape}.")
    return numpy.array(values, dtype=object).reshape(shape)


def text_of(name, value):
    if isinstance(value, bytes):
        return value.decode("utf-8")
    if not isinstance(value, str):
        raise ValueError(f"Der String-Tensor {name} enthält einen Wert, der kein Text ist: {value!r}")
    return value
