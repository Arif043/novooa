"""Gemeinsames der Keypoint-Dekodierung: Tensorform und Ergebnis `{index, x, y, score?}`."""


def keypoint_matrix(numpy, tensor, dimensions, transformation_type, expected):
    """Entfernt führende Batch-Achsen der Größe 1 bis zur erwarteten Zahl von Dimensionen."""
    array = numpy.asarray(tensor, dtype=numpy.float32)
    while array.ndim > dimensions and array.shape[0] == 1:
        array = array[0]
    if array.ndim != dimensions:
        raise ValueError(f"{transformation_type} erwartet {expected}, erhält die Form {list(array.shape)}.")
    return array


def keypoint(index, x, y, score=None):
    point = {"index": index, "x": float(x), "y": float(y)}
    return point if score is None else {**point, "score": float(score)}


def scale_of(value, transformation_type, name):
    if value is None:
        return 1.0, 1.0
    if not isinstance(value, dict) or not all(isinstance(value.get(axis), (int, float)) for axis in ("x", "y")):
        raise ValueError(f"{transformation_type} benötigt {name} als {{x, y}}.")
    return float(value["x"]), float(value["y"])
