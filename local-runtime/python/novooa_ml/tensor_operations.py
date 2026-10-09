"""Allgemeine Tensoroperationen, die Eingangs- und Ausgangstransformationen teilen.

Jede Funktion erhält numpy, einen Tensor und die Parameter aus dem Modellvertrag und liefert
einen neuen Tensor. Ungültige Parameter führen zu einer verständlichen ValueError.
"""

from numbers import Real


def scale(numpy, tensor, parameters):
    factor = number(parameters.get("factor", 1), "tensor.scale", "factor")
    offset = number(parameters.get("offset", 0), "tensor.scale", "offset")
    return (numpy.asarray(tensor, dtype=numpy.float32) * factor + offset).astype(numpy.float32)


def clip(numpy, tensor, parameters):
    minimum = optional_number(parameters.get("min"), "tensor.clip", "min")
    maximum = optional_number(parameters.get("max"), "tensor.clip", "max")
    if minimum is None and maximum is None:
        raise ValueError("tensor.clip benötigt min oder max.")
    if minimum is not None and maximum is not None and minimum > maximum:
        raise ValueError("tensor.clip: min darf nicht größer als max sein.")
    return numpy.clip(numpy.asarray(tensor), minimum, maximum)


def reshape(numpy, tensor, parameters):
    shape = parameters.get("shape")
    valid = isinstance(shape, list) and shape and all(
        is_integer(size) and (size > 0 or size == -1) for size in shape
    )
    if not valid:
        raise ValueError("tensor.reshape benötigt shape mit positiven ganzen Zahlen oder -1.")
    if shape.count(-1) > 1:
        raise ValueError("tensor.reshape erlaubt höchstens eine Dimension mit -1.")
    array = numpy.asarray(tensor)
    known = int(numpy.prod([size for size in shape if size != -1]))
    if array.size % known != 0 or (-1 not in shape and known != array.size):
        raise ValueError(f"tensor.reshape: Die Form {shape} passt nicht zu {array.size} Werten.")
    return array.reshape(shape)


def transpose(numpy, tensor, parameters):
    array = numpy.asarray(tensor)
    axes = parameters.get("axes")
    valid = isinstance(axes, list) and all(is_integer(axis) for axis in axes)
    if not valid or sorted(axes) != list(range(array.ndim)):
        raise ValueError(
            f"tensor.transpose benötigt axes als Permutation von 0 bis {array.ndim - 1}."
        )
    return array.transpose(axes)


def fit_length(numpy, tensor, parameters):
    """Füllt eine Achse mit `value` auf oder kürzt sie auf `length`; `keep` wählt die behaltene Seite."""
    array = numpy.asarray(tensor)
    length = parameters.get("length")
    if not is_integer(length) or length <= 0:
        raise ValueError("tensor.fitLength benötigt length als positive ganze Zahl.")
    keep = parameters.get("keep", "start")
    if keep not in ("start", "end"):
        raise ValueError("tensor.fitLength benötigt keep start oder end.")
    value = number(parameters.get("value", 0), "tensor.fitLength", "value")
    axis = axis_of(array, parameters, "tensor.fitLength") % array.ndim
    current = array.shape[axis]
    if current >= length:
        start = current - length if keep == "end" else 0
        return numpy.take(array, range(start, start + length), axis=axis)
    padding = [(0, 0)] * array.ndim
    padding[axis] = (length - current, 0) if keep == "end" else (0, length - current)
    return numpy.pad(array, padding, constant_values=value)


def axis_of(tensor, parameters, transformation_type):
    axis = parameters.get("axis", -1)
    if not is_integer(axis) or not -tensor.ndim <= axis < tensor.ndim:
        raise ValueError(
            f"{transformation_type}: Die Achse {axis} liegt außerhalb des Tensors "
            f"mit {tensor.ndim} Dimensionen."
        )
    return axis


def is_integer(value):
    return isinstance(value, int) and not isinstance(value, bool)


def number(value, transformation_type, name):
    if not isinstance(value, Real) or isinstance(value, bool):
        raise ValueError(f"{transformation_type} benötigt eine Zahl für {name}.")
    return float(value)


def optional_number(value, transformation_type, name):
    return None if value is None else number(value, transformation_type, name)
