from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.parameters import positive_integer
from novooa_ml.transformations.schema import Integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImageCenterCropStrategy(TransformationStrategy):
    """Schneidet einen Ausschnitt fester Größe aus der Bildmitte."""

    accepts = (IMAGE,)
    produces = IMAGE
    parameters = {"width": Integer(minimum=1), "height": Integer(minimum=1)}

    @property
    def transformation_type(self):
        return "image.centerCrop"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        width = positive_integer(parameters.get("width"))
        height = positive_integer(parameters.get("height"))
        image_width, image_height = image.size
        if width > image_width or height > image_height:
            raise ValueError(
                f"image.centerCrop: Der Ausschnitt {width}×{height} ist größer als das Bild "
                f"{image_width}×{image_height}."
            )
        left = (image_width - width) // 2
        top = (image_height - height) // 2
        return image.crop((left, top, left + width, top + height))
