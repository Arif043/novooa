from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.parameters import positive_integer
from novooa_ml.transformations.schema import Integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImageResizeShorterSideStrategy(TransformationStrategy):
    """Skaliert die kürzere Bildseite auf `size`; das Seitenverhältnis bleibt erhalten."""

    accepts = (IMAGE,)
    produces = IMAGE
    parameters = {"size": Integer(minimum=1)}

    @property
    def transformation_type(self):
        return "image.resizeShorterSide"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        size = positive_integer(parameters.get("size"))
        width, height = image.size
        ratio = size / min(width, height)
        target = (max(1, round(width * ratio)), max(1, round(height * ratio)))
        return image.resize(target, context.image_module.Resampling.LANCZOS)
