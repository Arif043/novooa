from .parameters import image_mode, positive_integer
from .strategy import InputTransformStrategy


class ImageResizeStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "image.resize"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        color_space = parameters.get("colorSpace")
        if color_space is not None:
            context.image = context.image.convert(image_mode(color_space))
        size = (positive_integer(parameters.get("width")), positive_integer(parameters.get("height")))
        context.image = context.image.resize(
            size, context.image_module.Resampling.LANCZOS
        )
