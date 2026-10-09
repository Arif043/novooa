from novooa_ml.transformations.parameters import axis_of
from novooa_ml.transformations.strategy import TransformationStrategy


class ArgmaxStrategy(TransformationStrategy):
    """Index des größten Werts entlang einer Achse, z. B. die wahrscheinlichste Klasse."""

    @property
    def transformation_type(self):
        return "tensor.argmax"

    def transform(self, value, parameters, context):
        tensor = context.numpy.asarray(value)
        axis = axis_of(tensor, parameters, self.transformation_type)
        return context.numpy.argmax(tensor, axis=axis)
