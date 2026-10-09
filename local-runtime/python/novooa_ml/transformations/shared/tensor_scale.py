from ..parameters import number
from ..strategy import TransformationStrategy
from ..values import as_tensor


class TensorScaleStrategy(TransformationStrategy):
    """Berechnet `wert × factor + offset` (Ein- und Ausgang)."""

    @property
    def transformation_type(self):
        return "tensor.scale"

    def transform(self, value, parameters, context):
        return scale(context.numpy, as_tensor(value, context), parameters)


def scale(numpy, tensor, parameters):
    factor = number(parameters.get("factor", 1), "tensor.scale", "factor")
    offset = number(parameters.get("offset", 0), "tensor.scale", "offset")
    return (numpy.asarray(tensor, dtype=numpy.float32) * factor + offset).astype(numpy.float32)
