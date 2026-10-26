from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.schema import Integer, ListOf, OutputName
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorConcatStrategy(TransformationStrategy):
    """Hängt Rohausgänge des Modells (`outputs`) entlang `axis` an den aktuellen Tensor an.

    So werden getrennte Ausgänge — Boxen, Scores, Labels — zu einer Zeile je Erkennung. Ein
    Tensor mit einer Dimension weniger erhält eine Achse der Größe 1 (`[1, 300]` neben
    `[1, 300, 4]`); verschiedene Datentypen werden zu float32.
    """

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"outputs": ListOf(OutputName()), "axis": Integer(optional=True, default=-1)}

    @property
    def transformation_type(self):
        return "tensor.concat"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        base = numpy.asarray(as_tensor(value, context))
        names = parameters.get("outputs")
        if not isinstance(names, list) or not names:
            raise ValueError("tensor.concat benötigt outputs als Liste von Ausgangsnamen.")
        others = [aligned(numpy, numpy.asarray(context.output_tensor(name, self.transformation_type)), base, name) for name in names]
        axis = axis_within(parameters.get("axis", -1), base.ndim)
        parts = [base, *others]
        if len({part.dtype for part in parts}) > 1:
            parts = [part.astype(numpy.float32) for part in parts]
        try:
            return numpy.concatenate(parts, axis=axis)
        except ValueError as error:
            shapes = ", ".join(str(list(part.shape)) for part in parts)
            raise ValueError(f"tensor.concat: Die Formen {shapes} passen entlang Achse {axis} nicht zusammen.") from error


def aligned(numpy, tensor, base, name):
    if tensor.ndim == base.ndim - 1:
        return numpy.expand_dims(tensor, -1)
    if tensor.ndim != base.ndim:
        raise ValueError(
            f"tensor.concat: Der Ausgang {name} hat {tensor.ndim} Dimensionen, erwartet sind {base.ndim} oder {base.ndim - 1}."
        )
    return tensor


def axis_within(axis, dimensions):
    if not is_integer(axis) or not -dimensions <= axis < dimensions:
        raise ValueError(f"tensor.concat: Die Achse {axis} liegt außerhalb des Tensors mit {dimensions} Dimensionen.")
    return axis
