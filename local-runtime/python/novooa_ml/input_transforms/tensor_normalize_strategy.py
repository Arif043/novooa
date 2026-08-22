from .parameters import numeric_values
from .strategy import InputTransformStrategy


class TensorNormalizeStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "tensor.normalize"

    def transform(self, context, parameters):
        tensor = context.tensor_array().astype(context.numpy.float32)
        mean = numeric_values(parameters.get("mean"), "mean")
        standard_deviation = numeric_values(parameters.get("std"), "std")
        channels = tensor.shape[0] if context.layout == "channelsFirst" else tensor.shape[-1]
        if len(mean) != channels or len(standard_deviation) != channels:
            raise ValueError("tensor.normalize benötigt Werte für jeden Farbkanal.")
        context.tensor = (tensor - channel_values(mean, context)) / channel_values(
            standard_deviation, context
        )


def channel_values(values, context):
    shape = (-1, 1, 1) if context.layout == "channelsFirst" else (1, 1, -1)
    return context.numpy.asarray(values, dtype=context.numpy.float32).reshape(shape)
