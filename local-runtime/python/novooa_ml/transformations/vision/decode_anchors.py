import json

from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.schema import ListOf, Number, Text
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor

from .box_decoding import BOX, SIZE_ENCODING, box_columns, decoded_size, decoding_rows


class TensorDecodeAnchorsStrategy(TransformationStrategy):
    """Dekodiert Boxen relativ zu Ankern (SSD, RetinaNet, BlazeFace).

    Die Anker stehen als Modellressource `anchors` (JSON-Liste `[[cx, cy, w, h], …]`, eine je
    Zeile). Je Zeile: `centerX = a_cx + x × v₀ × a_w`, `centerY = a_cy + y × v₀ × a_h`, Breite
    `a_w × exp(w × v₁)` (oder linear `a_w × w × v₁`) mit `variances = [v₀, v₁]`. Die Boxen haben die
    Einheit der Anker — normierte Anker brauchen danach `boxScale` in der NMS.
    """

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {
        "anchors": Text(),
        "box": BOX,
        "variances": ListOf(Number(minimum=0), length=2, optional=True, default=[0.1, 0.2]),
        "sizeEncoding": SIZE_ENCODING,
    }

    @property
    def transformation_type(self):
        return "tensor.decodeAnchors"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        rows = decoding_rows(numpy, as_tensor(value, context), self.transformation_type)
        columns = box_columns(parameters, rows.shape[1], self.transformation_type)
        anchors = anchors_from(numpy, context.resource_bytes(parameters.get("anchors")), parameters.get("anchors"))
        if anchors.shape[0] != rows.shape[0]:
            raise ValueError(f"tensor.decodeAnchors: {anchors.shape[0]} Anker passen nicht zu {rows.shape[0]} Zeilen.")
        center_variance, size_variance = parameters.get("variances", [0.1, 0.2])
        encoding = parameters.get("sizeEncoding", "exp")
        for key, origin, extent in (("centerX", 0, 2), ("centerY", 1, 3)):
            rows[:, columns[key]] = anchors[:, origin] + rows[:, columns[key]] * center_variance * anchors[:, extent]
        for key, extent in (("width", 2), ("height", 3)):
            size = decoded_size(numpy, rows[:, columns[key]] * size_variance, encoding, self.transformation_type)
            rows[:, columns[key]] = anchors[:, extent] * size
        return rows


def anchors_from(numpy, data, name):
    try:
        anchors = numpy.asarray(json.loads(data.decode("utf-8")), dtype=numpy.float32)
    except (ValueError, TypeError) as error:
        raise ValueError(f"tensor.decodeAnchors: Die Ressource {name} ist keine JSON-Liste von Ankern.") from error
    if anchors.ndim != 2 or anchors.shape[1] != 4:
        raise ValueError(f"tensor.decodeAnchors: Die Ressource {name} braucht je Anker [cx, cy, w, h].")
    return anchors
