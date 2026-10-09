from novooa_ml.transformations.strategy import TransformationStrategy


class TensorConstantStrategy(TransformationStrategy):
    """Ersetzt den Wert durch einen festen Zahlentensor `values` (z. B. für Hilfseingänge)."""

    @property
    def transformation_type(self):
        return "tensor.constant"

    def transform(self, value, parameters, context):
        values = parameters.get("values")
        if not isinstance(values, list) or not values or not all(isinstance(item, (int, float)) for item in values):
            raise ValueError("tensor.constant benötigt ein nicht leeres Zahlenfeld values.")
        return context.numpy.asarray(values, dtype=context.numpy.float32)
