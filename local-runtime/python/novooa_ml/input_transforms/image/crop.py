from novooa_ml.transformations.parameters import positive_integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImageCropStrategy(TransformationStrategy):
    """Schneidet einen achsenparallelen Bildbereich aus."""

    @property
    def transformation_type(self):
        return "image.crop"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        left = nonnegative_integer(parameters.get("left"), "left")
        top = nonnegative_integer(parameters.get("top"), "top")
        right = left + positive_integer(parameters.get("width"))
        bottom = top + positive_integer(parameters.get("height"))
        image_width, image_height = image.size
        if right > image_width or bottom > image_height:
            raise ValueError("image.crop liegt außerhalb des Bildes.")
        return image.crop((left, top, right, bottom))


def nonnegative_integer(value, name):
    if not isinstance(value, int) or value < 0:
        raise ValueError(f"image.crop benötigt eine nichtnegative Ganzzahl für {name}.")
    return value
