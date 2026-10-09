import base64
import io

from novooa_ml.transformations.kinds import IMAGE_FILE, TENSOR
from novooa_ml.transformations.schema import Choice, Integer, ListOf, Text
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.values import as_tensor

FORMATS = {"png": ("PNG", "image/png"), "jpeg": ("JPEG", "image/jpeg")}
# Kanäle → Pillow-Modus; zweidimensionale Tensoren sind Graustufen.
MODES = {1: "L", 3: "RGB", 4: "RGBA"}


class ImageEncodeStrategy(TransformationStrategy):
    """Kodiert einen Tensor als Bilddatei, z. B. eine Maske, Tiefenkarte oder ein verbessertes Bild.

    Form `[H, W]`, `[H, W, C]` oder mit `layout: channelsFirst` `[C, H, W]` (C = 1, 3, 4);
    Batch-Dimensionen der Größe 1 entfallen. Werte werden auf 0…255 begrenzt. Mit `palette`
    (Liste von `[r, g, b]`) werden Klassenindizes eingefärbt.
    """

    accepts = (TENSOR,)
    produces = IMAGE_FILE
    parameters = {
        "format": Choice("png", "jpeg", optional=True, default="png"),
        "fileName": Text(optional=True),
        "layout": Choice("channelsFirst", "channelsLast", optional=True, default="channelsLast"),
        "palette": ListOf(ListOf(Integer(minimum=0, maximum=255), length=3), optional=True),
    }

    @property
    def transformation_type(self):
        return "image.encode"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        pixels = pixels_for(numpy, as_tensor(value, context), parameters)
        image = context.image_module.fromarray(pixels, MODES[1 if pixels.ndim == 2 else pixels.shape[-1]])
        image_format, content_type = FORMATS[parameters.get("format", "png")]
        if image_format == "JPEG" and image.mode == "RGBA":
            image = image.convert("RGB")
        buffer = io.BytesIO()
        image.save(buffer, format=image_format)
        extension = "png" if image_format == "PNG" else "jpg"
        return {
            "dataBase64": base64.b64encode(buffer.getvalue()).decode("ascii"),
            "contentType": content_type,
            "fileName": parameters.get("fileName", f"modell-ausgabe.{extension}"),
        }


def pixels_for(numpy, tensor, parameters):
    palette = parameters.get("palette")
    if palette is not None:
        return colored(numpy, squeezed(tensor, 2), palette)
    tensor = squeezed(tensor, 3)
    if parameters.get("layout", "channelsLast") == "channelsFirst" and tensor.ndim == 3:
        tensor = numpy.moveaxis(tensor, 0, -1)
    if tensor.ndim == 3 and tensor.shape[-1] == 1:
        tensor = tensor[..., 0]
    if tensor.ndim != 2 and not (tensor.ndim == 3 and tensor.shape[-1] in (3, 4)):
        raise ValueError("image.encode erwartet [H, W], [H, W, C] oder [C, H, W] mit 1, 3 oder 4 Kanälen.")
    return numpy.rint(numpy.clip(tensor, 0, 255)).astype(numpy.uint8)


def colored(numpy, classes, palette):
    if classes.ndim != 2:
        raise ValueError("image.encode erwartet mit palette Klassenindizes der Form [H, W].")
    indexes = numpy.rint(classes).astype(int)
    outside = indexes[(indexes < 0) | (indexes >= len(palette))]
    if outside.size:
        raise ValueError(f"image.encode: Der Klassenindex {int(outside[0])} liegt außerhalb der Palette.")
    return numpy.asarray(palette, dtype=numpy.uint8)[indexes]


def squeezed(tensor, maximum_dimensions):
    while tensor.ndim > maximum_dimensions and tensor.shape[0] == 1:
        tensor = tensor[0]
    return tensor
