"""Gemeinsame Helfer für die Tests des ML-Dienstes."""

import base64
import io
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import numpy
from PIL import Image

from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.default_registry import default_transformation_registry

REGISTRY = default_transformation_registry()

_REPOSITORY = Path(__file__).resolve().parents[3]


def shipped_model_manifests():
    """Alle mitgelieferten Manifeste der Systemmodelle: `models/**/model.json`."""
    return sorted((_REPOSITORY / "models").rglob("model.json"))


def context(**options):
    return TransformationContext(numpy, image_module=Image, **options)


def run(value, *steps, ctx=None):
    """Führt (Typ, Parameter)-Paare über den gemeinsamen Katalog aus und liefert den Endwert."""
    transformations = [{"type": kind, "parameters": parameters} for kind, parameters in steps]
    return REGISTRY.run(value, transformations, ctx or context()).value


def png_base64(image):
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode("ascii")


def decoded_tensor(encoded):
    data_types = {"float32": numpy.float32, "int64": numpy.int64, "uint8": numpy.uint8}
    values = numpy.frombuffer(base64.b64decode(encoded["dataBase64"]), dtype=data_types[encoded["dataType"]])
    return values.reshape(encoded["shape"])
