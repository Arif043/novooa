from novooa_ml.transformations.kinds import DETECTIONS, TENSOR
from novooa_ml.transformations.schema import Integer, Number, Record
from novooa_ml.transformations.strategy import TransformationStrategy


class NonMaximumSuppressionStrategy(TransformationStrategy):
    """Unterdrückt überlappende Erkennungen und liefert `{index, score, box}`."""

    accepts = (TENSOR,)
    produces = DETECTIONS
    parameters = {
        "box": Record({name: Integer(minimum=0) for name in ("left", "top", "right", "bottom")}),
        "scoreIndex": Integer(minimum=0),
        "scoreThreshold": Number(optional=True),
        "iouThreshold": Number(minimum=0, maximum=1, optional=True, default=0.5),
    }

    @property
    def transformation_type(self):
        return "tensor.nonMaximumSuppression"

    def transform(self, value, parameters, context):
        if value.ndim != 2:
            raise ValueError("tensor.nonMaximumSuppression erwartet [erkennungen, werte].")
        box = parameters.get("box")
        if not isinstance(box, dict):
            raise ValueError("tensor.nonMaximumSuppression benötigt box.")
        indexes = {key: required_index(box.get(key)) for key in ("left", "top", "right", "bottom")}
        score_index = required_index(parameters.get("scoreIndex"))
        if max(*indexes.values(), score_index) >= value.shape[1]:
            raise ValueError("Ein Erkennungsindex liegt außerhalb der Tensorbreite.")
        threshold = numeric_parameter(parameters.get("scoreThreshold"), float("-inf"))
        iou_threshold = numeric_parameter(parameters.get("iouThreshold"), 0.5)
        if iou_threshold < 0 or iou_threshold > 1:
            raise ValueError("iouThreshold liegt außerhalb des erlaubten Bereichs.")
        detections = [
            detection(row, index, indexes, score_index)
            for index, row in enumerate(value)
            if float(row[score_index]) >= threshold
        ]
        return suppress_overlaps(detections, iou_threshold)


def detection(row, index, box_indexes, score_index):
    box = {key: float(row[value]) for key, value in box_indexes.items()}
    if box["right"] < box["left"] or box["bottom"] < box["top"]:
        raise ValueError("Eine Erkennungsbox ist ungültig.")
    return {"index": index, "score": float(row[score_index]), "box": box}


def suppress_overlaps(detections, threshold):
    accepted = []
    for candidate in sorted(detections, key=lambda item: item["score"], reverse=True):
        if all(iou(candidate["box"], item["box"]) <= threshold for item in accepted):
            accepted.append(candidate)
    return accepted


def iou(left, right):
    overlap_width = max(0, min(left["right"], right["right"]) - max(left["left"], right["left"]))
    overlap_height = max(0, min(left["bottom"], right["bottom"]) - max(left["top"], right["top"]))
    overlap = overlap_width * overlap_height
    left_area = (left["right"] - left["left"]) * (left["bottom"] - left["top"])
    right_area = (right["right"] - right["left"]) * (right["bottom"] - right["top"])
    return overlap / (left_area + right_area - overlap or 1)


def required_index(value):
    if not isinstance(value, int) or value < 0:
        raise ValueError("Ein Spaltenindex muss eine nichtnegative ganze Zahl sein.")
    return value


def numeric_parameter(value, fallback):
    if value is None:
        return fallback
    if not isinstance(value, (int, float)):
        raise ValueError("Der Transformationsparameter ist ungültig.")
    return value
