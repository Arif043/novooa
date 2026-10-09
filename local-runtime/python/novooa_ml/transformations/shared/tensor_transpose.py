from ..parameters import is_integer
from ..strategy import TransformationStrategy
from ..values import as_tensor


class TensorTransposeStrategy(TransformationStrategy):
    """Ordnet die Achsen nach einer vollständigen Permutation `axes` um (Ein- und Ausgang)."""

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
