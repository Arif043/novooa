from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.strategy import TransformationStrategy


class RoundStrategy(TransformationStrategy):
    """Rundet auf `decimals` Nachkommastellen (Standard: ganze Zahlen)."""

    accepts = (TENSOR,)
    produces = TENSOR

    @property
    def transformation_type(self):
        return "tensor.round"

    def transform(self, value, parameters, context):
        decimals = parameters.get("decimals", 0)
        if not is_integer(decimals) or decimals < 0:
            raise ValueError("tensor.round benötigt decimals als nichtnegative ganze Zahl.")
        return context.numpy.round(context.numpy.asarray(value, dtype=float), decimals)
