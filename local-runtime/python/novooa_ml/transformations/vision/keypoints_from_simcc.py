from novooa_ml.transformations.kinds import KEYPOINTS, TENSOR
from novooa_ml.transformations.parameters import number
from novooa_ml.transformations.schema import Number, OutputName
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor

from .keypoint_values import keypoint, keypoint_matrix


class KeypointsFromSimccStrategy(TransformationStrategy):
    """Dekodiert Keypoints aus SimCC-Klassifikationen je Achse (RTMPose).

    Der Ausgang liefert die x-Verteilungen `[K, Wx]`, der Rohausgang `yOutput` die y-Verteilungen
    `[K, Hy]`. Koordinate = Index des Maximums / `splitRatio`; Score ist das kleinere der beiden
    Maxima, wie in der Referenzimplementierung von MMPose.
    """

    accepts = (TENSOR,)
    produces = KEYPOINTS
    parameters = {"yOutput": OutputName(), "splitRatio": Number(minimum=0, optional=True, default=2.0)}

    @property
    def transformation_type(self):
        return "keypoints.fromSimcc"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        shape = "[K, Bins]"
        simcc_x = keypoint_matrix(numpy, as_tensor(value, context), 2, self.transformation_type, shape)
        raw_y = context.output_tensor(parameters.get("yOutput"), self.transformation_type)
        simcc_y = keypoint_matrix(numpy, raw_y, 2, self.transformation_type, shape)
        if simcc_x.shape[0] != simcc_y.shape[0]:
            raise ValueError(f"keypoints.fromSimcc: {simcc_x.shape[0]} x- und {simcc_y.shape[0]} y-Verteilungen passen nicht zusammen.")
        ratio = number(parameters.get("splitRatio", 2.0), self.transformation_type, "splitRatio")
        if ratio <= 0:
            raise ValueError("keypoints.fromSimcc benötigt splitRatio größer als 0.")
        x_index, y_index = simcc_x.argmax(axis=1), simcc_y.argmax(axis=1)
        scores = numpy.minimum(simcc_x.max(axis=1), simcc_y.max(axis=1))
        return [keypoint(index, x_index[index] / ratio, y_index[index] / ratio, scores[index]) for index in range(simcc_x.shape[0])]
