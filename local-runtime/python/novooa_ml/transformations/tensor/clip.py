from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import optional_number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorClipStrategy(TransformationStrategy):
    """Begrenzt Werte auf `min` und/oder `max` (Ein- und Ausgang)."""

    accepts = (TENSOR,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "tensor.clip"

    def transform(self, value, parameters, context):
        return clip(context.numpy, as_tensor(value, context), parameters)


def clip(numpy, tensor, parameters):
    minimum = optional_number(parameters.get("min"), "tensor.clip", "min")
    maximum = optional_number(parameters.get("max"), "tensor.clip", "max")
    if minimum is None and maximum is None:
        raise ValueError("tensor.clip benötigt min oder max.")
    if minimum is not None and maximum is not None and minimum > maximum:
        raise ValueError("tensor.clip: min darf nicht größer als max sein.")
    return numpy.clip(numpy.asarray(tensor), minimum, maximum)
