from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.schema import Integer, ListOf
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor

from .box_decoding import BOX, SIZE_ENCODING, box_columns, decoded_size, decoding_rows


class TensorDecodeGridStrategy(TransformationStrategy):
    """Dekodiert Rohboxen ankerfreier Detektoren (YOLOX, YuNet, FCOS) aus Rasterzellen.

    Die Zeilen folgen den Strides in Reihenfolge, je Stride zeilenweise über das Raster
    `(height/stride) × (width/stride)`. Je Zeile: `centerX = (x + spalte) × stride`,
    `centerY = (y + zeile) × stride`, Breite und Höhe `exp(w) × stride` (oder linear). Andere
    Spalten (Objectness, Klassen) bleiben unverändert; danach liest `tensor.nonMaximumSuppression`.
    """

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {
        "strides": ListOf(Integer(minimum=1)),
        "width": Integer(minimum=1),
        "height": Integer(minimum=1),
        "box": BOX,
        "sizeEncoding": SIZE_ENCODING,
    }

    @property
    def transformation_type(self):
        return "tensor.decodeGrid"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        rows = decoding_rows(numpy, as_tensor(value, context), self.transformation_type)
        columns = box_columns(parameters, rows.shape[1], self.transformation_type)
        grid_x, grid_y, strides = self.grid(numpy, parameters)
        if len(strides) != rows.shape[0]:
            raise ValueError(f"tensor.decodeGrid: Das Raster hat {len(strides)} Zellen, der Tensor {rows.shape[0]} Zeilen.")
        encoding = parameters.get("sizeEncoding", "exp")
        rows[:, columns["centerX"]] = (rows[:, columns["centerX"]] + grid_x) * strides
        rows[:, columns["centerY"]] = (rows[:, columns["centerY"]] + grid_y) * strides
        for key in ("width", "height"):
            rows[:, columns[key]] = decoded_size(numpy, rows[:, columns[key]], encoding, self.transformation_type) * strides
        return rows

    def grid(self, numpy, parameters):
        """Spalte, Zeile und Stride je Rasterzelle, in der Reihenfolge der Modellausgabe."""
        width, height, strides = parameters.get("width"), parameters.get("height"), parameters.get("strides")
        if not isinstance(strides, list) or not strides or not all(is_integer(stride) and stride > 0 for stride in strides):
            raise ValueError("tensor.decodeGrid benötigt strides als Liste positiver ganzer Zahlen.")
        cells_x, cells_y, cell_strides = [], [], []
        for stride in strides:
            if width % stride or height % stride:
                raise ValueError(f"tensor.decodeGrid: {width}×{height} ist nicht durch den Stride {stride} teilbar.")
            ys, xs = numpy.meshgrid(numpy.arange(height // stride), numpy.arange(width // stride), indexing="ij")
            cells_x.append(xs.reshape(-1))
            cells_y.append(ys.reshape(-1))
            cell_strides.append(numpy.full(xs.size, stride))
        return (numpy.concatenate(part).astype(numpy.float32) for part in (cells_x, cells_y, cell_strides))
