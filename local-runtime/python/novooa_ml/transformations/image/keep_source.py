import base64
import io

from novooa_ml.transformations.geometry import KEY as GEOMETRY
from novooa_ml.transformations.kinds import IMAGE
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.travelling_metadata import SOURCE_IMAGE
from novooa_ml.transformations.values import require_image


class ImageKeepSourceStrategy(TransformationStrategy):
    """Merkt sich das aktuelle Bild, damit ein Ausgang es weiterverarbeiten kann (`image.applyMask`).

    Das Bild reist als PNG in den Metadaten des Eingangs zum Ausgang. Es muss das Bild sein, auf
    das sich die Geometrie bezieht — also vor jedem Skalieren oder Zuschneiden stehen (nach
    `image.exifTranspose` ist erlaubt).
    """

    accepts = (IMAGE,)
    produces = IMAGE
    parameters = {}

    @property
    def transformation_type(self):
        return "image.keepSource"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        if not is_identity(context.metadata.get(GEOMETRY), image.size):
            raise ValueError("image.keepSource muss vor Schritten stehen, die das Bild skalieren, auffüllen oder zuschneiden.")
        buffer = io.BytesIO()
        image.save(buffer, format="PNG")
        context.metadata[SOURCE_IMAGE] = base64.b64encode(buffer.getvalue()).decode("ascii")
        return image


def is_identity(geometry, size):
    if geometry is None:
        return False
    unchanged = geometry["scaleX"] == 1 and geometry["scaleY"] == 1 and geometry["offsetX"] == 0 and geometry["offsetY"] == 0
    return unchanged and (geometry["sourceWidth"], geometry["sourceHeight"]) == tuple(size)
