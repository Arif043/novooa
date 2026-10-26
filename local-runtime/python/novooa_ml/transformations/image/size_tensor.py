from novooa_ml.transformations.geometry import KEY as GEOMETRY
from novooa_ml.transformations.kinds import IMAGE, TENSOR
from novooa_ml.transformations.schema import Choice, ListOf
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import require_image

IMAGE_VALUES = ("height", "width")
# Felder der Bildgeometrie (`transformations/geometry.py`).
GEOMETRY_VALUES = ("sourceHeight", "sourceWidth", "scaleY", "scaleX")


class ImageSizeTensorStrategy(TransformationStrategy):
    """Liefert Bildmaße als float32-Vektor für Hilfseingänge wie `im_shape` oder `scale_factor`.

    `height`/`width` sind die Maße des aktuellen (z. B. skalierten) Bildes, `sourceHeight`/
    `sourceWidth` die des Originals, `scaleY`/`scaleX` der Skalierungsfaktor dazwischen. Gedacht
    für einen abgeleiteten Eingang (`binding: derived`) mit denselben Bildschritten wie der
    Bildeingang.
    """

    accepts = (IMAGE,)
    produces = TENSOR
    parameters = {"values": ListOf(Choice(*IMAGE_VALUES, *GEOMETRY_VALUES))}

    @property
    def transformation_type(self):
        return "image.sizeTensor"

    def transform(self, value, parameters, context):
        image = require_image(value, self.transformation_type, context)
        names = parameters.get("values")
        if not isinstance(names, list) or not names:
            raise ValueError("image.sizeTensor benötigt values als nicht leere Liste.")
        width, height = image.size
        current = {"height": float(height), "width": float(width)}
        geometry = context.metadata.get(GEOMETRY)
        return context.numpy.asarray([self.value_of(name, current, geometry) for name in names], dtype=context.numpy.float32)

    def value_of(self, name, current, geometry):
        if name in current:
            return current[name]
        if name not in GEOMETRY_VALUES:
            raise ValueError(f"image.sizeTensor kennt den Wert {name} nicht.")
        if geometry is None:
            raise ValueError(f"image.sizeTensor: {name} lässt sich nach einem nicht umkehrbaren Bildschritt nicht bestimmen.")
        return float(geometry[name])
