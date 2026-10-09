from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.schema import Integer
from novooa_ml.transformations.strategy import TransformationStrategy


class SoftmaxStrategy(TransformationStrategy):
    """Normalisiert Werte entlang der letzten Achse zu Wahrscheinlichkeiten."""

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"axis": Integer(optional=True, default=-1)}

    @property
    def transformation_type(self):
        return "tensor.softmax"

    def transform(self, value, parameters, context):
        axis = parameters.get("axis", -1)
        if axis != -1:
            raise ValueError("tensor.softmax unterstützt nur die letzte Tensorachse.")
        maximum = context.numpy.max(value, axis=-1, keepdims=True)
        exponentials = context.numpy.exp(value - maximum)
        return exponentials / context.numpy.sum(exponentials, axis=-1, keepdims=True)
