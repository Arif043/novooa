from .image_decode_strategy import ImageDecodeStrategy
from .image_resize_strategy import ImageResizeStrategy
from .registry import TransformationRegistry
from .tensor_layout_strategy import TensorLayoutStrategy
from .tensor_normalize_strategy import TensorNormalizeStrategy


def default_transformation_registry():
    return TransformationRegistry(
        [
            ImageDecodeStrategy(),
            ImageResizeStrategy(),
            TensorLayoutStrategy(),
            TensorNormalizeStrategy(),
        ]
    )
