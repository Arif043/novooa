from novooa_ml.transformations.kinds import DETECTIONS, TENSOR
from novooa_ml.transformations.schema import Boolean, Choice, Integer, Number, OneOf, Record
from novooa_ml.transformations.strategy import TransformationStrategy

from .detection_rows import CENTER_KEYS, CORNER_KEYS, row_reader, suppress_overlaps


class NonMaximumSuppressionStrategy(TransformationStrategy):
    """Liest Erkennungen aus Zeilen `[Erkennungen, Werte]` und unterdrückt Überlappungen.

    Boxen als Ecken (`left/top/right/bottom`) oder Mittelpunkt (`centerX/centerY/width/height`),
    optional mit `boxScale` von 0…1 auf Pixel. Der Score kommt aus einer Spalte (`scoreIndex`)
    oder aus Klassenspalten (`classScores`, dann mit `classIndex`), optional mal `objectnessIndex`;
    `classColumn` liest die Klasse aus einer Spalte, `scoreActivation` macht Logits zu
    Wahrscheinlichkeiten. Mit Klassen wird je Klasse unterdrückt (`classAware`); `suppress: false`
    lässt die Unterdrückung aus (Exporte mit eingebauter NMS, DETR). Ergebnis: `{index, score,
    box, classIndex?}` nach Score sortiert, höchstens `maxDetections`.
    """

    accepts = (TENSOR,)
    produces = DETECTIONS
    parameters = {
        "box": OneOf(
            Record({name: Integer(minimum=0) for name in CORNER_KEYS}),
            Record({name: Integer(minimum=0) for name in CENTER_KEYS}),
        ),
        "scoreIndex": Integer(minimum=0, optional=True),
        "classColumn": Integer(minimum=0, optional=True),
        "scoreActivation": Choice("none", "sigmoid", "softmax", optional=True, default="none"),
        "suppress": Boolean(optional=True, default=True),
        "classScores": Record({"start": Integer(minimum=0), "end": Integer(minimum=1, optional=True)}, optional=True),
        "objectnessIndex": Integer(minimum=0, optional=True),
        "classAware": Boolean(optional=True, default=True),
        "boxScale": Record({"x": Number(minimum=0), "y": Number(minimum=0)}, optional=True),
        "scoreThreshold": Number(optional=True),
        "iouThreshold": Number(minimum=0, maximum=1, optional=True, default=0.5),
        "maxDetections": Integer(minimum=1, optional=True),
    }

    @property
    def transformation_type(self):
        return "tensor.nonMaximumSuppression"

    def transform(self, value, parameters, context):
        if value.ndim != 2:
            raise ValueError("tensor.nonMaximumSuppression erwartet [erkennungen, werte].")
        read = row_reader(parameters, value.shape[1], context.numpy)
        threshold = number(parameters.get("scoreThreshold"), float("-inf"))
        iou_threshold = number(parameters.get("iouThreshold"), 0.5)
        if iou_threshold < 0 or iou_threshold > 1:
            raise ValueError("iouThreshold liegt außerhalb des erlaubten Bereichs.")
        detections = [{"index": index, **read(row)} for index, row in enumerate(value)]
        candidates = [item for item in detections if item["score"] >= threshold]
        if parameters.get("suppress", True):
            accepted = suppress_overlaps(candidates, iou_threshold, parameters.get("classAware", True))
        else:
            accepted = sorted(candidates, key=lambda item: item["score"], reverse=True)
        limit = parameters.get("maxDetections")
        return accepted if limit is None else accepted[:limit]


def number(value, fallback):
    if value is None:
        return fallback
    if not isinstance(value, (int, float)):
        raise ValueError("Der Transformationsparameter ist ungültig.")
    return value
