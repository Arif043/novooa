from .image_crop_strategy import ImageCropStrategy
from .image_decode_strategy import ImageDecodeStrategy
from .image_perspective_crop_strategy import ImagePerspectiveCropStrategy
from .image_resize_strategy import ImageResizeStrategy
from .registry import TransformationRegistry
from .tensor_layout_strategy import TensorLayoutStrategy
from .tensor_normalize_strategy import TensorNormalizeStrategy


def default_transformation_registry():
    return TransformationRegistry(
        [
            ImageDecodeStrategy(),
            ImageCropStrategy(),
            ImagePerspectiveCropStrategy(),
            ImageResizeStrategy(),
            TensorLayoutStrategy(),
            TensorNormalizeStrategy(),
        ]
    )
