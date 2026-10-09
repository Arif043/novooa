from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.parameters import positive_integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImagePerspectiveCropStrategy(TransformationStrategy):
    """Richtet ein Viereck (vier Punkte) perspektivisch zu einem Bild aus."""

    accepts = (IMAGE,)
    produces = IMAGE

    @property
    def transformation_type(self):
        return "image.perspectiveCrop"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        points = quadrilateral(parameters.get("points"))
        width = positive_integer(parameters.get("width"))
        height = positive_integer(parameters.get("height"))
        return image.transform(
            (width, height),
            context.image_module.Transform.QUAD,
            points,
            resample=context.image_module.Resampling.BICUBIC,
        )


def quadrilateral(value):
    if not isinstance(value, list) or len(value) != 8:
        raise ValueError("image.perspectiveCrop benötigt vier Punkte als acht Zahlen.")
    if not all(isinstance(item, (int, float)) for item in value):
        raise ValueError("image.perspectiveCrop benötigt numerische Punkte.")
    return tuple(value)
