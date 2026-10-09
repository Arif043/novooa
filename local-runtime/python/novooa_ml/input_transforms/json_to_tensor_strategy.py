from numbers import Real

from .strategy import InputTransformStrategy


class JsonToTensorStrategy(InputTransformStrategy):
    """Wandelt eine Zahl, einen Wahrheitswert oder verschachtelte Zahlenlisten in einen Tensor."""

    @property
    def transformation_type(self):
        return "json.toTensor"

    def transform(self, context, parameters):
        value = context.value if isinstance(context.value, list) else [context.value]
        if not value or not is_rectangular(value):
            raise ValueError(
                "json.toTensor benötigt eine Zahl, einen Wahrheitswert oder gleich lange, "
                "nicht leere Zahlenlisten."
            )
        context.tensor = context.numpy.asarray(value, dtype=context.numpy.float32)


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
