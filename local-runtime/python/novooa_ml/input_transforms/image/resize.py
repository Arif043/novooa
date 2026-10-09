from novooa_ml.transformations.parameters import image_mode, positive_integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImageResizeStrategy(TransformationStrategy):
    """Skaliert auf feste Breite und Höhe (LANCZOS), optional mit Farbraumwechsel."""

    @property
    def transformation_type(self):
        return "image.resize"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        color_space = parameters.get("colorSpace")
        if color_space is not None:
            image = image.convert(image_mode(color_space))
        size = (positive_integer(parameters.get("width")), positive_integer(parameters.get("height")))
        return image.resize(size, context.image_module.Resampling.LANCZOS)
