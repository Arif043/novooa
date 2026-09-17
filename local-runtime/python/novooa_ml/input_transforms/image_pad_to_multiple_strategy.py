from .parameters import image_mode, positive_integer
from .strategy import InputTransformStrategy


class ImagePadToMultipleStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "image.padToMultiple"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        color_space = parameters.get("colorSpace")
        if color_space is not None:
            context.image = context.image.convert(image_mode(color_space))
        multiple = positive_integer(parameters.get("multiple"))
        background = background_for(parameters.get("background", 0))
        image = context.image
        size = padded_size(image.size, multiple)
        if size == image.size:
            return
        canvas = context.image_module.new(image.mode, size, background)
        canvas.paste(image, (0, 0))
        context.image = canvas


def background_for(value):
    if not isinstance(value, int) or value < 0 or value > 255:
        raise ValueError("image.padToMultiple benötigt eine Hintergrundfarbe zwischen 0 und 255.")
    return value


def padded_size(size, multiple):
    return tuple(next_multiple(value, multiple) for value in size)


def next_multiple(value, multiple):
    return ((value + multiple - 1) // multiple) * multiple
