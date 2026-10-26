from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import number
from novooa_ml.transformations.schema import Number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorMinMaxScaleStrategy(TransformationStrategy):
    """Skaliert die Werte linear vom eigenen Minimum und Maximum auf `[minimum, maximum]`.

    Für Ausgaben ohne festen Wertebereich, etwa relative Tiefen- oder Saliency-Karten, die als
    Bild gespeichert werden (`maximum: 255`). Ein konstanter Tensor ergibt überall `minimum`.
    """

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"minimum": Number(optional=True, default=0), "maximum": Number(optional=True, default=1)}

    @property
    def transformation_type(self):
        return "tensor.minMaxScale"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        tensor = numpy.asarray(as_tensor(value, context), dtype=numpy.float32)
        low = number(parameters.get("minimum", 0), self.transformation_type, "minimum")
        high = number(parameters.get("maximum", 1), self.transformation_type, "maximum")
        if high <= low:
            raise ValueError("tensor.minMaxScale benötigt maximum größer als minimum.")
        if tensor.size == 0:
            raise ValueError("tensor.minMaxScale erwartet einen nicht leeren Tensor.")
        smallest, largest = float(tensor.min()), float(tensor.max())
        if largest == smallest:
            return numpy.full(tensor.shape, low, dtype=numpy.float32)
        return ((tensor - smallest) / (largest - smallest) * (high - low) + low).astype(numpy.float32)
