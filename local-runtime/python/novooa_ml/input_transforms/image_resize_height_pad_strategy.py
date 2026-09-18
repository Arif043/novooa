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
        width = positive_integer(parameters.get("width"))
        height = positive_integer(parameters.get("height"))
        alignment = alignment_for(parameters.get("alignment", "topLeft"))
        background = background_for(parameters.get("background", 0))
        resized = resized_to_height(context.image, height, context.image_module)
        context.image = padded_or_cropped(
            resized, width, height, alignment, background, context.image_module
        )


def resized_to_height(image, target_height, image_module):
    ratio = target_height / image.size[1]
    width = max(1, round(image.size[0] * ratio))
    return image.resize((width, target_height), image_module.Resampling.LANCZOS)


def padded_or_cropped(image, width, height, alignment, background, image_module):
    if image.size[0] >= width:
        return image.crop((0, 0, width, height))
    canvas = image_module.new(image.mode, (width, height), background)
    offset = 0 if alignment == "topLeft" else (width - image.size[0]) // 2
    canvas.paste(image, (offset, 0))
    return canvas
