from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.schema import Integer, ListOf
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorReshapeStrategy(TransformationStrategy):
    """Formt den Tensor um; höchstens eine Dimension darf -1 sein (Ein- und Ausgang)."""

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"shape": ListOf(Integer(minimum=-1))}

    @property
    def transformation_type(self):
        return "tensor.reshape"

    def transform(self, value, parameters, context):
        return reshape(context.numpy, as_tensor(value, context), parameters)


def reshape(numpy, tensor, parameters):
    shape = parameters.get("shape")
    valid = isinstance(shape, list) and shape and all(
        is_integer(size) and (size > 0 or size == -1) for size in shape
    )
    if not valid:
        raise ValueError("tensor.reshape benötigt shape mit positiven ganzen Zahlen oder -1.")
    if shape.count(-1) > 1:
        raise ValueError("tensor.reshape erlaubt höchstens eine Dimension mit -1.")
    array = numpy.asarray(tensor)
    known = int(numpy.prod([size for size in shape if size != -1]))
    if array.size % known != 0 or (-1 not in shape and known != array.size):
        raise ValueError(f"tensor.reshape: Die Form {shape} passt nicht zu {array.size} Werten.")
    return array.reshape(shape)
