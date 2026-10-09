from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class TensorLayoutStrategy(TransformationStrategy):
    """Ordnet ein Bild zwischen HWC (`channelsLast`) und CHW (`channelsFirst`) um.

    Das gewählte Layout merkt sich der Kontext, damit `tensor.normalize` die Kanalachse kennt.
    """

    accepts = (TENSOR,)
    produces = TENSOR

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
        context.metadata["layout"] = requested
        return tensor.transpose((2, 0, 1) if requested == "channelsFirst" else (1, 2, 0))


def layout_of(context):
    return context.metadata.get("layout", "channelsLast")
