from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import axis_of, is_integer, number
from novooa_ml.transformations.schema import Choice, Integer, Number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorFitLengthStrategy(TransformationStrategy):
    """Füllt eine Achse mit `value` auf oder kürzt sie auf `length` (Ein- und Ausgang)."""

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"length": Integer(minimum=1), "axis": Integer(optional=True, default=-1), "value": Number(optional=True, default=0), "keep": Choice("start", "end", optional=True, default="start")}

    @property
    def transformation_type(self):
        return "tensor.fitLength"

    def transform(self, value, parameters, context):
        return fit_length(context.numpy, as_tensor(value, context), parameters)


def fit_length(numpy, tensor, parameters):
    """`keep` wählt die behaltene Seite: `end` behält die jüngsten Werte (Zeitreihen-Fenster)."""
    array = numpy.asarray(tensor)
    length = parameters.get("length")
    if not is_integer(length) or length <= 0:
        raise ValueError("tensor.fitLength benötigt length als positive ganze Zahl.")
    keep = parameters.get("keep", "start")
    if keep not in ("start", "end"):
        raise ValueError("tensor.fitLength benötigt keep start oder end.")
    value = number(parameters.get("value", 0), "tensor.fitLength", "value")
    axis = axis_of(array, parameters, "tensor.fitLength") % array.ndim
    current = array.shape[axis]
    if current >= length:
        start = current - length if keep == "end" else 0
        return numpy.take(array, range(start, start + length), axis=axis)
    padding = [(0, 0)] * array.ndim
    padding[axis] = (length - current, 0) if keep == "end" else (0, length - current)
    return numpy.pad(array, padding, constant_values=value)
