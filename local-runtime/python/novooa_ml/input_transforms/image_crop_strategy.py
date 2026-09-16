from .parameters import positive_integer
from .strategy import InputTransformStrategy


class ImageCropStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "image.crop"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        left = nonnegative_integer(parameters.get("left"), "left")
        top = nonnegative_integer(parameters.get("top"), "top")
        width = positive_integer(parameters.get("width"))
        height = positive_integer(parameters.get("height"))
        right = left + width
        bottom = top + height
        image_width, image_height = context.image.size
        if right > image_width or bottom > image_height:
            raise ValueError("image.crop liegt außerhalb des Bildes.")
        context.image = context.image.crop((left, top, right, bottom))


def nonnegative_integer(value, name):
    if not isinstance(value, int) or value < 0:
        raise ValueError(f"image.crop benötigt eine nichtnegative Ganzzahl für {name}.")
    return value
