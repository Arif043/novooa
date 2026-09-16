from .registry import OutputTransformationStrategy


class SoftmaxStrategy(OutputTransformationStrategy):
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


class SigmoidStrategy(OutputTransformationStrategy):
    @property
    def transformation_type(self):
        return "tensor.sigmoid"

    def transform(self, value, parameters, context):
        return 1 / (1 + context.numpy.exp(-value))


class ThresholdStrategy(OutputTransformationStrategy):
    @property
    def transformation_type(self):
        return "tensor.threshold"

    def transform(self, value, parameters, context):
        threshold = parameters.get("value", 0.5)
        if not isinstance(threshold, (int, float)):
            raise ValueError("tensor.threshold benötigt einen numerischen Wert.")
        return value >= threshold


class TopKStrategy(OutputTransformationStrategy):
    @property
    def transformation_type(self):
        return "tensor.topK"

    def transform(self, value, parameters, context):
        if value.ndim > 1 and context.numpy.prod(value.shape[:-1]) != 1:
            raise ValueError("tensor.topK unterstützt nur einzelne Vektoren.")
        descriptor = parameters.get("parameter")
        if not isinstance(descriptor, dict):
            raise ValueError("tensor.topK benötigt eine Parameterbeschreibung.")
        count = context.parameter_value(descriptor)
        values = value.reshape(-1)
        indexes = context.numpy.argsort(values)[::-1][:count]
        return [
            {"index": int(index), "value": float(values[index])}
            for index in indexes
        ]
