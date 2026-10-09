from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.schema import Integer, ListOf
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorTransposeStrategy(TransformationStrategy):
    """Ordnet die Achsen nach einer vollständigen Permutation `axes` um (Ein- und Ausgang)."""

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"axes": ListOf(Integer(minimum=0))}

    @property
    def transformation_type(self):
        return "tensor.transpose"

    def transform(self, value, parameters, context):
        return transpose(context.numpy, as_tensor(value, context), parameters)


def transpose(numpy, tensor, parameters):
    array = numpy.asarray(tensor)
    axes = parameters.get("axes")
    valid = isinstance(axes, list) and all(is_integer(axis) for axis in axes)
    if not valid or sorted(axes) != list(range(array.ndim)):
        raise ValueError(f"tensor.transpose benötigt axes als Permutation von 0 bis {array.ndim - 1}.")
    return array.transpose(axes)
