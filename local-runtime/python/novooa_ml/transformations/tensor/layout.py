from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.schema import Choice
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorLayoutStrategy(TransformationStrategy):
    """Ordnet ein Bild zwischen HWC (`channelsLast`) und CHW (`channelsFirst`) um.

    Ein Batch (`[N, H, W, C]`, etwa aus `image.tiles`) wird je Bild umgeordnet. Das gewählte
    Layout merkt sich der Kontext, damit `tensor.normalize` die Kanalachse kennt.
    """

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {"order": Choice("channelsFirst", "channelsLast")}

    @property
    def transformation_type(self):
        return "tensor.layout"

    def transform(self, value, parameters, context):
        requested = parameters.get("order")
        if requested not in ["channelsFirst", "channelsLast"]:
            raise ValueError("tensor.layout benötigt channelsFirst oder channelsLast.")
        tensor = as_tensor(value, context)
        if requested == layout_of(context):
            return tensor
        if tensor.ndim not in (3, 4):
            raise ValueError("tensor.layout erwartet ein Bild [H, W, C] oder einen Batch [N, H, W, C].")
        context.metadata["layout"] = requested
        batch = (0,) if tensor.ndim == 4 else ()
        offset = len(batch)
        order = (2, 0, 1) if requested == "channelsFirst" else (1, 2, 0)
        return tensor.transpose(batch + tuple(axis + offset for axis in order))


def layout_of(context):
    return context.metadata.get("layout", "channelsLast")
