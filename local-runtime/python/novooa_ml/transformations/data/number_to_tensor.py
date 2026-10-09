from numbers import Real

from novooa_ml.transformations.kinds import NUMBER, TENSOR
from novooa_ml.transformations.strategy import TransformationStrategy


class NumberToTensorStrategy(TransformationStrategy):
    """Macht aus einer Zahl oder Zahlenliste einen eindimensionalen float32-Tensor."""

    accepts = (NUMBER,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "number.toTensor"

    def transform(self, value, parameters, context):
        values = value if isinstance(value, list) else [value]
        if not values or not all(is_number(value) for value in values):
            raise ValueError("number.toTensor benötigt eine Zahl oder eine nicht leere Zahlenliste.")
        return context.numpy.asarray(values, dtype=context.numpy.float32)


def is_number(value):
    return isinstance(value, Real) and not isinstance(value, bool)
