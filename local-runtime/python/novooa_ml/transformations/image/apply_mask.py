import base64
import io

from novooa_ml.transformations.kinds import IMAGE_FILE, TENSOR
from novooa_ml.transformations.schema import Choice, Text
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.travelling_metadata import SOURCE_IMAGE
from novooa_ml.transformations.values import as_tensor
from novooa_ml.transformations.vision.mask_to_source import indexes, squeezed


class ImageApplyMaskStrategy(TransformationStrategy):
    """Setzt eine Maske des Modells als Alphakanal auf das Originalbild (Freistellen).

    Die Maske `[H, W]` liegt im Modellbild; über die Geometrie des Eingangs `input` wird sie auf das
    Originalbild abgebildet, das `image.keepSource` dort gemerkt hat. `range: unit` erwartet Werte
    0…1 (z. B. nach `tensor.sigmoid`), `range: byte` 0…255. Ergebnis ist ein PNG mit Transparenz.
    """

    accepts = (TENSOR,)
    produces = IMAGE_FILE
    parameters = {
        "input": Text(),
        "range": Choice("unit", "byte", optional=True, default="unit"),
        "fileName": Text(optional=True, default="freigestellt.png"),
    }

    @property
    def transformation_type(self):
        return "image.applyMask"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        name = parameters.get("input")
        geometry = context.input_geometry(name, self.transformation_type)
        encoded = context.input_metadata(name, SOURCE_IMAGE, self.transformation_type, "kein Quellbild (image.keepSource fehlt)")
        source = context.image_module.open(io.BytesIO(base64.b64decode(encoded))).convert("RGBA")
        mask = squeezed(numpy.asarray(as_tensor(value, context), dtype=numpy.float32), 2)
        if mask.ndim != 2:
            raise ValueError("image.applyMask erwartet eine Maske [H, W].")
        rows, row_valid = indexes(numpy, geometry["sourceHeight"], geometry["scaleY"], geometry["offsetY"], mask.shape[0])
        columns, column_valid = indexes(numpy, geometry["sourceWidth"], geometry["scaleX"], geometry["offsetX"], mask.shape[1])
        factor = 255.0 if parameters.get("range", "unit") == "unit" else 1.0
        alpha = numpy.clip(mask[numpy.ix_(rows, columns)] * factor, 0, 255) * numpy.outer(row_valid, column_valid)
        pixels = numpy.asarray(source).copy()
        pixels[..., 3] = numpy.rint(alpha).astype(numpy.uint8)
        return png_file(context.image_module.fromarray(pixels, "RGBA"), parameters.get("fileName", "freigestellt.png"))


def png_file(image, file_name):
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return {"dataBase64": base64.b64encode(buffer.getvalue()).decode("ascii"), "contentType": "image/png", "fileName": file_name}
