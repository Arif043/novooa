from .parameters import image_mode, positive_integer
from .strategy import InputTransformStrategy


class ImageResizePadStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "image.resizePad"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        color_space = parameters.get("colorSpace")
        if color_space is not None:
            context.image = context.image.convert(image_mode(color_space))
        target_width = positive_integer(parameters.get("width"))
        target_height = positive_integer(parameters.get("height"))
        alignment = alignment_for(parameters.get("alignment", "topLeft"))
        background = background_for(parameters.get("background", 0))
        image = context.image
        scale = min(target_width / image.size[0], target_height / image.size[1])
        size = scaled_size(image.size, scale)
        resized = image.resize(size, context.image_module.Resampling.LANCZOS)
        canvas = context.image_module.new(image.mode, (target_width, target_height), background)
        canvas.paste(resized, offset_for((target_width, target_height), size, alignment))
        context.image = canvas


def alignment_for(value):
    if value not in ("topLeft", "center"):
        raise ValueError("image.resizePad unterstützt topLeft oder center.")
    return value


def background_for(value):
    if not isinstance(value, int) or value < 0 or value > 255:
        raise ValueError("image.resizePad benötigt eine Hintergrundfarbe zwischen 0 und 255.")
    return value


def scaled_size(size, scale):
    return tuple(max(1, round(value * scale)) for value in size)


def offset_for(target, size, alignment):
    if alignment == "topLeft":
        return (0, 0)
    return ((target[0] - size[0]) // 2, (target[1] - size[1]) // 2)
