from novooa_ml.transformations.parameters import image_mode, positive_integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImagePadToMultipleStrategy(TransformationStrategy):
    """Füllt rechts und unten bis zu einem Vielfachen auf; Bildkoordinaten bleiben erhalten."""

    @property
    def transformation_type(self):
        return "image.padToMultiple"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        color_space = parameters.get("colorSpace")
        if color_space is not None:
            image = image.convert(image_mode(color_space))
        multiple = positive_integer(parameters.get("multiple"))
        background = background_for(parameters.get("background", 0))
        size = padded_size(image.size, multiple)
        if size == image.size:
            return image
        canvas = context.image_module.new(image.mode, size, background)
        canvas.paste(image, (0, 0))
        return canvas


def background_for(value):
    if not isinstance(value, int) or value < 0 or value > 255:
        raise ValueError("image.padToMultiple benötigt eine Hintergrundfarbe zwischen 0 und 255.")
    return value


def padded_size(size, multiple):
    return tuple(next_multiple(value, multiple) for value in size)


def next_multiple(value, multiple):
    return ((value + multiple - 1) // multiple) * multiple
