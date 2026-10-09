from numbers import Real

from novooa_ml.transformations.kinds import JSON, TENSOR
from novooa_ml.transformations.strategy import TransformationStrategy


class JsonToTensorStrategy(TransformationStrategy):
    """Wandelt Zahlen, Wahrheitswerte oder Texte (auch verschachtelt) in einen Tensor.

    Zahlen und Wahrheitswerte ergeben `float32`, Texte einen String-Tensor, etwa für
    Kategoriespalten klassischer ML-Modelle. Gemischte Listen sind ein Fehler.
    """

    accepts = (JSON,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "json.toTensor"

    def transform(self, value, parameters, context):
        values = value if isinstance(value, list) else [value]
        if not values or shape_of(values) is None:
            raise ValueError(
                "json.toTensor benötigt Zahlen, Wahrheitswerte oder Texte in gleich langen, "
                "nicht leeren Listen."
            )
        leaves = list(flatten(values))
        if all(isinstance(leaf, str) for leaf in leaves):
            return context.numpy.array(values, dtype=object)
        if all(isinstance(leaf, Real) for leaf in leaves):
            return context.numpy.asarray(values, dtype=context.numpy.float32)
        raise ValueError("json.toTensor: Zahlen und Texte dürfen nicht gemischt werden.")


def shape_of(value):
    """Form einer rechteckigen Verschachtelung oder None."""
    if isinstance(value, (Real, str)):
        return ()
    if not isinstance(value, list) or not value:
        return None
    shapes = {shape_of(item) for item in value}
    if len(shapes) != 1 or None in shapes:
        return None
    return (len(value), *shapes.pop())


def flatten(value):
    if isinstance(value, list):
        for item in value:
            yield from flatten(item)
    else:
        yield value
