import base64


def tensor_for_contract(tensor, definition, numpy):
    """Fügt bei Bedarf die Batch-Dimension hinzu, prüft die Form und kodiert den Tensor."""
    expected_shape = definition["shape"]
    if len(expected_shape) == tensor.ndim + 1:
        tensor = numpy.expand_dims(tensor, axis=0)
    validate_shape(definition["name"], tensor.shape, expected_shape)
    tensor = numpy.ascontiguousarray(tensor.astype(numpy_data_type(definition["dataType"], numpy)))
    return {
        "name": definition["name"],
        "dataType": definition["dataType"],
        "shape": list(tensor.shape),
        "dataBase64": base64.b64encode(tensor.tobytes()).decode("ascii"),
    }


def validate_shape(name, shape, definition):
    matches = len(shape) == len(definition) and all(
        expected == "dynamic" or expected == actual
        for actual, expected in zip(shape, definition, strict=True)
    )
    if not matches:
        raise ValueError(
            f"Eingang {name}: Die Transformationen erzeugten die Form {list(shape)}, "
            f"der Vertrag erwartet {list(definition)}."
        )


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
