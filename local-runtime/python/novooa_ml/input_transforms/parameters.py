def image_mode(color_space):
    modes = {"rgb": "RGB", "rgba": "RGBA", "grayscale": "L"}
    if color_space not in modes:
        raise ValueError("image.decode benötigt rgb, rgba oder grayscale.")
    return modes[color_space]


def positive_integer(value):
    if not isinstance(value, int) or value <= 0:
        raise ValueError("Bildmaße müssen positive ganze Zahlen sein.")
    return value


def numeric_values(value, name):
    valid = isinstance(value, list) and all(
        isinstance(item, (int, float)) for item in value
    )
    if not valid:
        raise ValueError(f"tensor.normalize benötigt ein Zahlenarray für {name}.")
    if name == "std" and any(item == 0 for item in value):
        raise ValueError("tensor.normalize erlaubt keine Standardabweichung von null.")
    return value
