import base64
import io

from .context import ImageTransformContext
from .default_registry import default_transformation_registry
from .output_tensor import tensor_for_contract


def transform_payload(payload):
    numpy, image = runtime_dependencies()
    context = image_context(payload, image, numpy)
    transformed = default_transformation_registry().apply(
        context, payload["input"]["preprocessing"]
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


def image_context(payload, image, numpy):
    image_bytes = base64.b64decode(payload["source"]["dataBase64"], validate=True)
    decoded = image.open(io.BytesIO(image_bytes))
    return ImageTransformContext(decoded, numpy, image)
