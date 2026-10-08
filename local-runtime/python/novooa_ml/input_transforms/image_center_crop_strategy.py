from .parameters import positive_integer
from .strategy import InputTransformStrategy


class ImageCenterCropStrategy(InputTransformStrategy):
    """Schneidet einen Ausschnitt fester Größe aus der Bildmitte."""

    @property
    def transformation_type(self):
        return "image.centerCrop"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        width = positive_integer(parameters.get("width"))
        height = positive_integer(parameters.get("height"))
        image_width, image_height = context.image.size
        if width > image_width or height > image_height:
            raise ValueError(
                f"image.centerCrop: Der Ausschnitt {width}×{height} ist größer als das Bild "
                f"{image_width}×{image_height}."
            )
        left = (image_width - width) // 2
        top = (image_height - height) // 2
        context.image = context.image.crop((left, top, left + width, top + height))
