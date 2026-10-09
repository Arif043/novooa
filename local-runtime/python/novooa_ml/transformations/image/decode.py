from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.parameters import image_mode
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImageDecodeStrategy(TransformationStrategy):
    """Setzt den Farbraum des Bildes: rgb, rgba oder grayscale."""

    accepts = (IMAGE,)
    produces = IMAGE

    @property
    def transformation_type(self):
        return "image.decode"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        return image.convert(image_mode(parameters.get("colorSpace")))
