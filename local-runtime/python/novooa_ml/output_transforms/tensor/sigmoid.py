from novooa_ml.transformations.strategy import TransformationStrategy


class SigmoidStrategy(TransformationStrategy):
    """Wandelt Logits elementweise in Wahrscheinlichkeiten."""

    @property
    def transformation_type(self):
        return "tensor.sigmoid"

    def transform(self, value, parameters, context):
        return 1 / (1 + context.numpy.exp(-value))
