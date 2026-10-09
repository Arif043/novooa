from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import axis_of
from novooa_ml.transformations.strategy import TransformationStrategy


class ReduceStrategy(TransformationStrategy):
    """Verdichtet eine Achse per Mittelwert, Summe, Maximum oder Minimum."""

    accepts = (TENSOR,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "tensor.reduce"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        operations = {"mean": numpy.mean, "sum": numpy.sum, "max": numpy.max, "min": numpy.min}
        operation = operations.get(parameters.get("operation"))
        if operation is None:
            raise ValueError("tensor.reduce benötigt operation mean, sum, max oder min.")
        tensor = numpy.asarray(value)
        return operation(tensor, axis=axis_of(tensor, parameters, self.transformation_type))
