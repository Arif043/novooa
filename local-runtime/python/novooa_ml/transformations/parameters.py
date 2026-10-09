"""Prüfung von Transformationsparametern mit verständlichen Fehlermeldungen."""

from numbers import Real


def is_integer(value):
    return isinstance(value, int) and not isinstance(value, bool)


def number(value, transformation_type, name):
    if not isinstance(value, Real) or isinstance(value, bool):
        raise ValueError(f"{transformation_type} benötigt eine Zahl für {name}.")
    return float(value)


def optional_number(value, transformation_type, name):
    return None if value is None else number(value, transformation_type, name)


def positive_integer(value):
    if not isinstance(value, int) or value <= 0:
        raise ValueError("Bildmaße müssen positive ganze Zahlen sein.")
    return value


def image_mode(color_space):
    modes = {"rgb": "RGB", "rgba": "RGBA", "grayscale": "L"}
    if color_space not in modes:
        raise ValueError("image.decode benötigt rgb, rgba oder grayscale.")
    return modes[color_space]


def numeric_values(value, name):
    valid = isinstance(value, list) and all(isinstance(item, (int, float)) for item in value)
    if not valid:
        raise ValueError(f"tensor.normalize benötigt ein Zahlenarray für {name}.")
    if name == "std" and any(item == 0 for item in value):
        raise ValueError("tensor.normalize erlaubt keine Standardabweichung von null.")
    return value


def axis_of(tensor, parameters, transformation_type):
    axis = parameters.get("axis", -1)
    if not is_integer(axis) or not -tensor.ndim <= axis < tensor.ndim:
        raise ValueError(
            f"{transformation_type}: Die Achse {axis} liegt außerhalb des Tensors "
            f"mit {tensor.ndim} Dimensionen."
        )
    return axis
