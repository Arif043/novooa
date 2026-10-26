from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import numeric_values
from novooa_ml.transformations.schema import ListOf, Number
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor

from .layout import layout_of


class TensorNormalizeStrategy(TransformationStrategy):
    """Normalisiert jeden Farbkanal: (wert − mean) / std, passend zum aktuellen Layout; auch je Bild eines Batches."""

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"mean": ListOf(Number()), "std": ListOf(Number())}

    @property
    def transformation_type(self):
        return "tensor.normalize"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        tensor = as_tensor(value, context).astype(numpy.float32)
        mean = numeric_values(parameters.get("mean"), "mean")
        standard_deviation = numeric_values(parameters.get("std"), "std")
        channels_first = layout_of(context) == "channelsFirst"
        channels = tensor.shape[-3] if channels_first else tensor.shape[-1]
        if len(mean) != channels or len(standard_deviation) != channels:
            raise ValueError("tensor.normalize benötigt Werte für jeden Farbkanal.")
        shape = (-1, 1, 1) if channels_first else (1, 1, -1)
        return (tensor - channel_values(mean, shape, numpy)) / channel_values(standard_deviation, shape, numpy)


def channel_values(values, shape, numpy):
    return numpy.asarray(values, dtype=numpy.float32).reshape(shape)
