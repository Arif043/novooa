from novooa_ml.transformations.kinds import JSON_RESULT, TENSOR
from novooa_ml.transformations.strategy import TransformationStrategy


class TopKStrategy(TransformationStrategy):
    """Liefert die k größten Werte eines Vektors als `{index, value}`."""

    accepts = (TENSOR,)
    produces = JSON_RESULT

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
