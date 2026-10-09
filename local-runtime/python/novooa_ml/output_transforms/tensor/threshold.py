from novooa_ml.transformations.strategy import TransformationStrategy


class ThresholdStrategy(TransformationStrategy):
    """Wandelt Werte in eine boolesche Maske (`wert >= value`)."""

    @property
    def transformation_type(self):
        return "tensor.threshold"

    def transform(self, value, parameters, context):
        threshold = parameters.get("value", 0.5)
        if not isinstance(threshold, (int, float)):
            raise ValueError("tensor.threshold benötigt einen numerischen Wert.")
        return value >= threshold
