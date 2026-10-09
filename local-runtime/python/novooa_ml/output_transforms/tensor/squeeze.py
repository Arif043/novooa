from novooa_ml.transformations.strategy import TransformationStrategy


class SqueezeStrategy(TransformationStrategy):
    """Entfernt Dimensionen der Größe 1, z. B. die Batch-Dimension."""

    @property
    def transformation_type(self):
        return "tensor.squeeze"

    def transform(self, value, parameters, context):
        return context.numpy.squeeze(context.numpy.asarray(value))
