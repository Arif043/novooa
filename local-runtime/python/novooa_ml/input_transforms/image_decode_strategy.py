from .parameters import image_mode
from .strategy import InputTransformStrategy


class ImageDecodeStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "image.decode"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        context.image = context.image.convert(image_mode(parameters.get("colorSpace")))
