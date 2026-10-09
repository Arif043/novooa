import base64
import io

from .context import (
    AudioTransformContext,
    ImageTransformContext,
    NumberTransformContext,
    TextTransformContext,
    ValueTransformContext,
)
from .default_registry import default_transformation_registry
from .output_tensor import tensor_for_contract
from .wav_decoder import decode_wav


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
    source_type = source["type"]
    if source_type == "text":
        return TextTransformContext(source["value"], numpy, resource_reader)
    if source_type == "number":
        return NumberTransformContext(source["value"], numpy, resource_reader)
    if source_type in ("json", "boolean"):
        return ValueTransformContext(source["value"], numpy, resource_reader)
    if source_type == "image":
        decoded = image.open(io.BytesIO(source_bytes(source)))
        return ImageTransformContext(decoded, numpy, image, resource_reader)
    if source_type == "audio":
        samples, sample_rate = decode_wav(source_bytes(source), source.get("contentType", ""))
        return AudioTransformContext(samples, sample_rate, numpy, resource_reader)
    raise ValueError(
        f"Die Eingabequelle {source_type} wird von der lokalen Transformation nicht unterstützt."
    )


def source_bytes(source):
    return base64.b64decode(source["dataBase64"], validate=True)
