from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.schema import Choice, Number, Text
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor


class MaskToSourceStrategy(TransformationStrategy):
    """Bildet eine Maske oder Karte aus dem Modellbild auf die Größe des Originalbildes ab.

    Nearest-Neighbour über die Geometrie des Eingangs `input`; Bereiche, die im Modellbild nur
    Rand waren, erhalten `fill`. Form `[H, W]`, `[C, H, W]` oder mit `layout: channelsLast`
    `[H, W, C]`; führende Batch-Dimensionen der Größe 1 entfallen.
    """

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {
        "input": Text(),
        "layout": Choice("channelsFirst", "channelsLast", optional=True, default="channelsFirst"),
        "fill": Number(optional=True, default=0),
    }

    @property
    def transformation_type(self):
        return "mask.toSource"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        geometry = context.input_geometry(parameters.get("input"), self.transformation_type)
        channels_last = parameters.get("layout", "channelsFirst") == "channelsLast"
        mask = squeezed(as_tensor(value, context), 3 if channels_last else 2)
        if mask.ndim not in ((2, 3) if not channels_last else (3,)) and not (channels_last and mask.ndim == 2):
            raise ValueError("mask.toSource erwartet [H, W], [C, H, W] oder [H, W, C].")
        height_axis, width_axis = (mask.ndim - 3, mask.ndim - 2) if channels_last and mask.ndim == 3 else (mask.ndim - 2, mask.ndim - 1)
        rows, row_valid = indexes(numpy, geometry["sourceHeight"], geometry["scaleY"], geometry["offsetY"], mask.shape[height_axis])
        columns, column_valid = indexes(numpy, geometry["sourceWidth"], geometry["scaleX"], geometry["offsetX"], mask.shape[width_axis])
        sampled = numpy.take(numpy.take(mask, rows, axis=height_axis), columns, axis=width_axis)
        valid = numpy.outer(row_valid, column_valid)
        valid = valid[..., None] if channels_last and mask.ndim == 3 else valid
        return numpy.where(valid, sampled, parameters.get("fill", 0))


def squeezed(tensor, minimum_dimensions):
    while tensor.ndim > minimum_dimensions and tensor.shape[0] == 1:
        tensor = tensor[0]
    return tensor


def indexes(numpy, source_size, scale, offset, model_size):
    """Modellpixel unter jedem Pixelmittelpunkt des Quellbildes, dazu ob es im Modellbild liegt."""
    positions = numpy.floor((numpy.arange(source_size) + 0.5) * scale + offset).astype(int)
    valid = (positions >= 0) & (positions < model_size)
    return numpy.clip(positions, 0, model_size - 1), valid
