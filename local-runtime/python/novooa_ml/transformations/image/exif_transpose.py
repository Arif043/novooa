from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImageExifTransposeStrategy(TransformationStrategy):
    """Dreht Fotos so, wie die Kamera sie laut EXIF-Ausrichtung aufgenommen hat."""

    accepts = (IMAGE,)
    produces = IMAGE

    @property
    def transformation_type(self):
        return "image.exifTranspose"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        from PIL import ImageOps

        return ImageOps.exif_transpose(image)
