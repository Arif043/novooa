from numbers import Real

from .strategy import InputTransformStrategy


class NumberToTensorStrategy(InputTransformStrategy):
    """Macht aus einer Zahl oder Zahlenliste einen eindimensionalen float32-Tensor."""

    @property
    def transformation_type(self):
        return "number.toTensor"

    def transform(self, context, parameters):
        values = context.value if isinstance(context.value, list) else [context.value]
        if not values or not all(is_number(value) for value in values):
            raise ValueError("number.toTensor benötigt eine Zahl oder eine nicht leere Zahlenliste.")
        context.tensor = context.numpy.asarray(values, dtype=context.numpy.float32)


def is_number(value):
    return isinstance(value, Real) and not isinstance(value, bool)
