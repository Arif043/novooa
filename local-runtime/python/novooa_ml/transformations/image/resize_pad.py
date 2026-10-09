from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.parameters import image_mode, positive_integer
from novooa_ml.transformations.schema import Choice, Integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image

from .image_canvas import alignment_for, background_for


class ImageResizePadStrategy(TransformationStrategy):
    """Erhält das Seitenverhältnis und füllt bis zur Zielgröße auf."""

    accepts = (IMAGE,)
    produces = IMAGE
    parameters = {"width": Integer(minimum=1), "height": Integer(minimum=1), "alignment": Choice("topLeft", "center", optional=True, default="topLeft"), "background": Integer(minimum=0, maximum=255, optional=True, default=0), "colorSpace": Choice("rgb", "rgba", "grayscale", optional=True)}

    @property
    def transformation_type(self):
        return "image.resizePad"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        color_space = parameters.get("colorSpace")
        if color_space is not None:
            image = image.convert(image_mode(color_space))
        target = (positive_integer(parameters.get("width")), positive_integer(parameters.get("height")))
        alignment = alignment_for(parameters.get("alignment", "topLeft"))
        background = background_for(parameters.get("background", 0))
        scale = min(target[0] / image.size[0], target[1] / image.size[1])
        size = scaled_size(image.size, scale)
        resized = image.resize(size, context.image_module.Resampling.LANCZOS)
        canvas = context.image_module.new(image.mode, target, background)
        canvas.paste(resized, offset_for(target, size, alignment))
        return canvas


def scaled_size(size, scale):
    return tuple(max(1, round(value * scale)) for value in size)


def offset_for(target, size, alignment):
    if alignment == "topLeft":
        return (0, 0)
    return ((target[0] - size[0]) // 2, (target[1] - size[1]) // 2)
