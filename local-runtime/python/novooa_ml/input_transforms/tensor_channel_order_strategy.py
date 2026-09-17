from .strategy import InputTransformStrategy


class TensorChannelOrderStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "tensor.channelOrder"

    def transform(self, context, parameters):
        order = channel_order(parameters.get("order"), context.tensor_array().shape[-1])
        context.tensor = context.tensor_array()[..., order]


def channel_order(value, channel_count):
    if not isinstance(value, list) or not all(isinstance(item, int) for item in value):
        raise ValueError("tensor.channelOrder benötigt eine Kanalreihenfolge aus Indizes.")
    if sorted(value) != list(range(channel_count)):
        raise ValueError("tensor.channelOrder muss jeden Kanal genau einmal enthalten.")
    return value
