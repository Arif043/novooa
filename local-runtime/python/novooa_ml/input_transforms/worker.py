from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.values import as_tensor

from .default_registry import default_transformation_registry
from .output_tensor import tensor_for_contract
from .sources import initial_value


def transform_payload(payload, resource_reader=None):
    numpy, image = runtime_dependencies()
    context = TransformationContext(numpy, image_module=image, resource_reader=resource_reader)
    value = initial_value(payload["source"], image)
    result = default_transformation_registry().run(value, payload["input"]["transformations"], context)
    return {"tensor": tensor_for_contract(as_tensor(result.value, context), payload["input"], numpy)}


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
