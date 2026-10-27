from novooa_ml.transformations.geometry import resize_geometry
from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.schema import Integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image


class ImageResizeWithinStrategy(TransformationStrategy):
    """Skaliert ein Bild nur, wenn es außerhalb von Grenzen liegt; das Seitenverhältnis bleibt.

    Zuerst wird verkleinert, bis die längere Seite höchstens `maxSide` misst, danach vergrößert,
    bis die kürzere Seite mindestens `minSide` misst — wie die Vorverarbeitung von PaddleOCR und
    RapidOCR (`limit_side_len`). Liegt das Bild innerhalb, bleibt es unverändert.
    """

    accepts = (IMAGE,)
    produces = IMAGE
    parameters = {"minSide": Integer(minimum=1, optional=True), "maxSide": Integer(minimum=1, optional=True)}

    @property
    def transformation_type(self):
        return "image.resizeWithin"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        minimum, maximum = parameters.get("minSide"), parameters.get("maxSide")
        if minimum is None and maximum is None:
            raise ValueError("image.resizeWithin benötigt minSide, maxSide oder beides.")
        ratio = scale_ratio(image.size, minimum, maximum)
        if ratio == 1:
            return image
        target = (max(1, round(image.size[0] * ratio)), max(1, round(image.size[1] * ratio)))
        resize_geometry(context, image.size, target)
        return image.resize(target, context.image_module.Resampling.LANCZOS)


def scale_ratio(size, minimum, maximum):
    width, height = size
    ratio = 1.0
    if maximum is not None and max(width, height) > maximum:
        ratio = maximum / max(width, height)
    if minimum is not None and min(width, height) * ratio < minimum:
        ratio = minimum / min(width, height)
    return ratio
