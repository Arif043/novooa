from novooa_ml.transformations.kinds import KEYPOINTS, TENSOR
from novooa_ml.transformations.parameters import column_index
from novooa_ml.transformations.schema import Integer, Number, Record
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor

from .keypoint_values import keypoint, keypoint_matrix, scale_of


class KeypointsFromRowsStrategy(TransformationStrategy):
    """Liest Keypoints aus Zeilen `[punkte, werte]`, eine Zeile je Punkt (z. B. MoveNet).

    `x`, `y` und optional `score` nennen die Spalten; `scale` rechnet normierte Koordinaten
    (0…1) in Modellpixel um. Führende Batch-Achsen der Größe 1 entfallen (`[1, 1, 17, 3]`).
    """

    accepts = (TENSOR,)
    produces = KEYPOINTS
    parameters = {
        "x": Integer(minimum=0),
        "y": Integer(minimum=0),
        "score": Integer(minimum=0, optional=True),
        "scale": Record({"x": Number(minimum=0), "y": Number(minimum=0)}, optional=True),
    }

    @property
    def transformation_type(self):
        return "keypoints.fromRows"

    def transform(self, value, parameters, context):
        rows = keypoint_matrix(context.numpy, as_tensor(value, context), 2, self.transformation_type, "[punkte, werte]")
        score = parameters.get("score")
        columns = [column_index(parameters.get("x")), column_index(parameters.get("y"))]
        columns += [column_index(score)] if score is not None else []
        if max(columns) >= rows.shape[1]:
            raise ValueError(f"keypoints.fromRows: Eine Spalte liegt außerhalb der Breite {rows.shape[1]}.")
        scale_x, scale_y = scale_of(parameters.get("scale"), self.transformation_type, "scale")
        return [
            keypoint(index, row[columns[0]] * scale_x, row[columns[1]] * scale_y, None if score is None else row[score])
            for index, row in enumerate(rows)
        ]
