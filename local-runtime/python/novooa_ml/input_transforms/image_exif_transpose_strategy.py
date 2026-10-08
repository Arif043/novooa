from .strategy import InputTransformStrategy


class ImageExifTransposeStrategy(InputTransformStrategy):
    """Dreht Fotos so, wie die Kamera sie laut EXIF-Ausrichtung aufgenommen hat."""

    @property
    def transformation_type(self):
        return "image.exifTranspose"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        from PIL import ImageOps

        context.image = ImageOps.exif_transpose(context.image)
