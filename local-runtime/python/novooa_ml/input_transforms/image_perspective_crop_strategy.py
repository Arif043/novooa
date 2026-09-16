from .parameters import positive_integer
from .strategy import InputTransformStrategy


class ImagePerspectiveCropStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "image.perspectiveCrop"

    def transform(self, context, parameters):
        context.require_image(self.transformation_type)
        points = quadrilateral(parameters.get("points"))
        width = positive_integer(parameters.get("width"))
        height = positive_integer(parameters.get("height"))
        context.image = context.image.transform(
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
