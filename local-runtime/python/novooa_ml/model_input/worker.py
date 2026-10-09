from novooa_ml.transformations.context import TransformationContext
from novooa_ml.transformations.default_registry import default_transformation_registry
from novooa_ml.transformations.pipeline_check import check_input_pipeline
from novooa_ml.transformations.values import as_tensor

from .sources import initial_value
from .tensor_encoding import tensor_for_contract


def transform_payload(payload, resource_reader=None):
    """Quelle → Eingangspipeline → Tensor in der Form, die der Modellvertrag erwartet."""
    numpy, image = runtime_dependencies()
    definition = payload["input"]
    registry = default_transformation_registry()
    check_input_pipeline(definition["name"], payload["source"]["type"], definition["transformations"], registry)
    context = TransformationContext(numpy, image_module=image, resource_reader=resource_reader)
    value = initial_value(payload["source"], image)
    result = registry.run(value, definition["transformations"], context)
    return {"tensor": tensor_for_contract(as_tensor(result.value, context), definition, numpy)}


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
