from numbers import Real

from novooa_ml.transformations.kinds import JSON, TENSOR
from novooa_ml.transformations.strategy import TransformationStrategy


class JsonToTensorStrategy(TransformationStrategy):
    """Wandelt eine Zahl, einen Wahrheitswert oder verschachtelte Zahlenlisten in einen Tensor."""

    accepts = (JSON,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "json.toTensor"

    def transform(self, value, parameters, context):
        values = value if isinstance(value, list) else [value]
        if not values or not is_rectangular(values):
            raise ValueError(
                "json.toTensor benötigt eine Zahl, einen Wahrheitswert oder gleich lange, "
                "nicht leere Zahlenlisten."
            )
        return context.numpy.asarray(values, dtype=context.numpy.float32)


def is_rectangular(value):
    if not isinstance(value, list):
        return isinstance(value, Real)
    if not value:
        return False
    shapes = {shape_of(item) for item in value}
    return len(shapes) == 1 and None not in shapes


def shape_of(value):
    if isinstance(value, Real):
        return ()
    if not isinstance(value, list) or not is_rectangular(value):
        return None
    return (len(value), shape_of(value[0]))
