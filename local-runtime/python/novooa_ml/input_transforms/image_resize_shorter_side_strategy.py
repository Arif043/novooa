from .parameters import positive_integer
from .strategy import InputTransformStrategy


class ImageResizeShorterSideStrategy(InputTransformStrategy):
    """Skaliert die kürzere Bildseite auf `size`; das Seitenverhältnis bleibt erhalten."""

    @property
    def transformation_type(self):
        return "image.resizeShorterSide"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        size = positive_integer(parameters.get("size"))
        width, height = context.image.size
        ratio = size / min(width, height)
        target = (max(1, round(width * ratio)), max(1, round(height * ratio)))
        context.image = context.image.resize(
            target, context.image_module.Resampling.LANCZOS
        )
