from novooa_ml.transformations.kinds import KEYPOINTS, TENSOR
from novooa_ml.transformations.schema import Choice, Number, Record
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor

from .keypoint_values import keypoint, keypoint_matrix, scale_of


class KeypointsFromHeatmapsStrategy(TransformationStrategy):
    """Liest je Heatmap den Punkt mit dem höchsten Wert (HRNet, ViTPose, Landmarken-Modelle).

    Form `[K, H, W]` oder mit `layout: channelsLast` `[H, W, K]`; `stride` rechnet die
    Heatmap-Zelle in Modellpixel um (z. B. 4 bei einer Heatmap in Viertelauflösung). Score ist der
    Höchstwert der Karte.
    """

    accepts = (TENSOR,)
    produces = KEYPOINTS
    parameters = {
        "stride": Record({"x": Number(minimum=0), "y": Number(minimum=0)}, optional=True),
        "layout": Choice("channelsFirst", "channelsLast", optional=True, default="channelsFirst"),
    }

    @property
    def transformation_type(self):
        return "keypoints.fromHeatmaps"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        maps = keypoint_matrix(numpy, as_tensor(value, context), 3, self.transformation_type, "[K, H, W] oder [H, W, K]")
        if parameters.get("layout", "channelsFirst") == "channelsLast":
            maps = numpy.moveaxis(maps, -1, 0)
        stride_x, stride_y = scale_of(parameters.get("stride"), self.transformation_type, "stride")
        flat = maps.reshape(maps.shape[0], -1)
        best = flat.argmax(axis=1)
        rows, columns = numpy.unravel_index(best, maps.shape[1:])
        return [
            keypoint(index, columns[index] * stride_x, rows[index] * stride_y, flat[index, best[index]])
            for index in range(maps.shape[0])
        ]
