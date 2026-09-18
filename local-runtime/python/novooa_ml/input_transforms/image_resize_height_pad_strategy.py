from .image_resize_pad_strategy import alignment_for, background_for
from .parameters import image_mode, positive_integer
from .strategy import InputTransformStrategy


class ImageResizeHeightPadStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "image.resizeHeightPad"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        color_space = parameters.get("colorSpace")
        if color_space is not None:
            context.image = context.image.convert(image_mode(color_space))
        height = positive_integer(parameters.get("height"))
        width = optional_positive_integer(parameters.get("width"), "width")
        multiple = optional_positive_integer(parameters.get("widthMultiple"), "widthMultiple")
        alignment = alignment_for(parameters.get("alignment", "topLeft"))
        background = background_for(parameters.get("background", 0))
        resized = resized_to_height(context.image, height, context.image_module)
        context.image = padded_image(
            resized, width, multiple, alignment, background, context.image_module
        )


def resized_to_height(image, target_height, image_module):
    ratio = target_height / image.size[1]
    width = max(1, round(image.size[0] * ratio))
    return image.resize((width, target_height), image_module.Resampling.LANCZOS)


def padded_image(image, width, multiple, alignment, background, image_module):
    if width is not None:
        return fixed_width_image(image, width, alignment, background, image_module)
    target_width = rounded_width(image.size[0], multiple)
    canvas = image_module.new(image.mode, (target_width, image.size[1]), background)
    canvas.paste(image, (0, 0))
    return canvas


def fixed_width_image(image, width, alignment, background, image_module):
    if image.size[0] >= width:
        return image.crop((0, 0, width, image.size[1]))
    canvas = image_module.new(image.mode, (width, image.size[1]), background)
    offset = 0 if alignment == "topLeft" else (width - image.size[0]) // 2
    canvas.paste(image, (offset, 0))
    return canvas


def rounded_width(width, multiple):
    if multiple is None:
        return width
    return ((width + multiple - 1) // multiple) * multiple


def optional_positive_integer(value, name):
    if value is None:
        return None
    try:
        return positive_integer(value)
    except ValueError as error:
        raise ValueError(f"image.resizeHeightPad benötigt eine positive Ganzzahl für {name}.") from error
