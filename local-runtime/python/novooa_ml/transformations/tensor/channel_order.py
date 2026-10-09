from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.schema import Integer, ListOf
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorChannelOrderStrategy(TransformationStrategy):
    """Ordnet die Farbkanäle (letzte Achse) über eine vollständige Indexpermutation um."""

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"order": ListOf(Integer(minimum=0))}

    @property
    def transformation_type(self):
        return "tensor.channelOrder"

    def transform(self, value, parameters, context):
        tensor = as_tensor(value, context)
        return tensor[..., channel_order(parameters.get("order"), tensor.shape[-1])]


def channel_order(value, channel_count):
    if not isinstance(value, list) or not all(isinstance(item, int) for item in value):
        raise ValueError("tensor.channelOrder benötigt eine Kanalreihenfolge aus Indizes.")
    if sorted(value) != list(range(channel_count)):
        raise ValueError("tensor.channelOrder muss jeden Kanal genau einmal enthalten.")
    return value
