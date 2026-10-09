"""Liest Erkennungen aus Tensorzeilen: Box-Format, Score oder beste Klasse, und unterdrückt Überlappungen."""

CORNER_KEYS = ("left", "top", "right", "bottom")
CENTER_KEYS = ("centerX", "centerY", "width", "height")


def row_reader(parameters, width):
    """Prüft die Spaltenangaben und liefert eine Funktion Zeile → Erkennung oder None."""
    box = parameters.get("box")
    if not isinstance(box, dict):
        raise ValueError("tensor.nonMaximumSuppression benötigt box.")
    keys = CENTER_KEYS if "centerX" in box else CORNER_KEYS
    box_columns = {key: required_index(box.get(key)) for key in keys}
    scoring = score_reader(parameters, width)
    if max(box_columns.values()) >= width:
        raise ValueError("Ein Erkennungsindex liegt außerhalb der Tensorbreite.")
    scale_x, scale_y = box_scale(parameters.get("boxScale"))

    def read(row):
        corners = corners_of(row, box_columns, scale_x, scale_y)
        return {"box": corners, **scoring(row)}

    return read


def score_reader(parameters, width):
    score_index, class_scores = parameters.get("scoreIndex"), parameters.get("classScores")
    if score_index is None and class_scores is None:
        raise ValueError("tensor.nonMaximumSuppression benötigt scoreIndex oder classScores.")
    if score_index is not None and class_scores is not None:
        raise ValueError("tensor.nonMaximumSuppression benötigt entweder scoreIndex oder classScores.")
    objectness = parameters.get("objectnessIndex")
    last = [required_index(objectness)] if objectness is not None else []
    if score_index is not None:
        column = required_index(score_index)
        within_width([column, *last], width)
        return lambda row: {"score": float(row[column]) * objectness_of(row, objectness)}
    start = required_index(class_scores.get("start"))
    end = class_scores.get("end", width)
    within_width([start, required_index(end) - 1, *last], width)
    if end <= start:
        raise ValueError("classScores benötigt end größer als start.")

    def best_class(row):
        scores = row[start:end]
        best = int(scores.argmax())
        return {"score": float(scores[best]) * objectness_of(row, objectness), "classIndex": best}

    return best_class


def corners_of(row, columns, scale_x, scale_y):
    values = {key: float(row[column]) for key, column in columns.items()}
    if "centerX" in values:
        half_width, half_height = values["width"] / 2, values["height"] / 2
        values = {
            "left": values["centerX"] - half_width, "top": values["centerY"] - half_height,
            "right": values["centerX"] + half_width, "bottom": values["centerY"] + half_height,
        }
    box = {
        "left": values["left"] * scale_x, "top": values["top"] * scale_y,
        "right": values["right"] * scale_x, "bottom": values["bottom"] * scale_y,
    }
    if box["right"] < box["left"] or box["bottom"] < box["top"]:
        raise ValueError("Eine Erkennungsbox ist ungültig.")
    return box


def suppress_overlaps(detections, threshold, class_aware):
    accepted = []
    for candidate in sorted(detections, key=lambda item: item["score"], reverse=True):
        rivals = [item for item in accepted if not class_aware or item.get("classIndex") == candidate.get("classIndex")]
        if all(iou(candidate["box"], item["box"]) <= threshold for item in rivals):
            accepted.append(candidate)
    return accepted


def iou(left, right):
    overlap_width = max(0, min(left["right"], right["right"]) - max(left["left"], right["left"]))
    overlap_height = max(0, min(left["bottom"], right["bottom"]) - max(left["top"], right["top"]))
    overlap = overlap_width * overlap_height
    left_area = (left["right"] - left["left"]) * (left["bottom"] - left["top"])
    right_area = (right["right"] - right["left"]) * (right["bottom"] - right["top"])
    return overlap / (left_area + right_area - overlap or 1)


def objectness_of(row, column):
    return 1.0 if column is None else float(row[column])


def box_scale(value):
    if value is None:
        return 1.0, 1.0
    return float(value["x"]), float(value["y"])


def within_width(columns, width):
    if max(columns) >= width:
        raise ValueError("Ein Erkennungsindex liegt außerhalb der Tensorbreite.")


def required_index(value):
    if not isinstance(value, int) or isinstance(value, bool) or value < 0:
        raise ValueError("Ein Spaltenindex muss eine nichtnegative ganze Zahl sein.")
    return value
