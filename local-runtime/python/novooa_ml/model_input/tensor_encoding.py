from novooa_ml.tensor_codec import STRING, encode_tensor, numpy_data_type


def tensor_for_contract(tensor, definition, numpy):
    """Fügt bei Bedarf die Batch-Dimension hinzu, prüft die Form und kodiert den Tensor."""
    expected_shape = definition["shape"]
    if len(expected_shape) == tensor.ndim + 1:
        tensor = numpy.expand_dims(tensor, axis=0)
    validate_shape(definition["name"], tensor.shape, expected_shape)
    validate_value_kind(definition["name"], tensor, definition["dataType"])
    converted = numpy.ascontiguousarray(tensor.astype(numpy_data_type(definition["dataType"], numpy)))
    return encode_tensor(definition["name"], converted, numpy)


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


def validate_value_kind(name, tensor, data_type):
    """Texte gehören in String-Tensoren, Zahlen in Zahlentensoren."""
    is_text = tensor.dtype.kind in "OUS"
    if is_text != (data_type == STRING):
        produced = "Texte" if is_text else "Zahlen"
        raise ValueError(
            f"Eingang {name}: Die Transformationen erzeugten {produced}, der Vertrag erwartet {data_type}."
        )
