import base64
import io

from .context import ImageTransformContext, NumberTransformContext, TextTransformContext
from .default_registry import default_transformation_registry
from .output_tensor import tensor_for_contract


def transform_payload(payload, resource_reader=None):
    numpy, image = runtime_dependencies()
    context = transformation_context(payload, image, numpy, resource_reader)
    transformed = default_transformation_registry().apply(
        context, payload["input"]["transformations"]
    )
    return {"tensor": tensor_for_contract(transformed, payload["input"])}


def runtime_dependencies():
    try:
        import numpy
        from PIL import Image
        return numpy, Image
    except ImportError as error:
        raise RuntimeError(
            "Die lokale Bildtransformation benötigt numpy und Pillow. "
            "Installiere local-runtime/python/requirements.txt."
        ) from error


def transformation_context(payload, image, numpy, resource_reader=None):
    source = payload["source"]
    if source["type"] == "text":
        return TextTransformContext(source["value"], numpy, resource_reader)
    if source["type"] == "number":
        return NumberTransformContext(source["value"], numpy, resource_reader)
    if source["type"] != "image":
        raise ValueError("Die Eingabequelle wird von der lokalen Transformation nicht unterstützt.")
    image_bytes = base64.b64decode(source["dataBase64"], validate=True)
    decoded = image.open(io.BytesIO(image_bytes))
    return ImageTransformContext(decoded, numpy, image, resource_reader)
