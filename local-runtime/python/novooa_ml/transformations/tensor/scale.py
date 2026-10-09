from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import number
from novooa_ml.transformations.schema import Number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorScaleStrategy(TransformationStrategy):
    """Berechnet `wert × factor + offset` (Ein- und Ausgang)."""

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"factor": Number(optional=True, default=1), "offset": Number(optional=True, default=0)}

    @property
    def transformation_type(self):
        return "tensor.scale"

    def transform(self, value, parameters, context):
        return scale(context.numpy, as_tensor(value, context), parameters)


def scale(numpy, tensor, parameters):
    factor = number(parameters.get("factor", 1), "tensor.scale", "factor")
    offset = number(parameters.get("offset", 0), "tensor.scale", "offset")
    return (numpy.asarray(tensor, dtype=numpy.float32) * factor + offset).astype(numpy.float32)
