from .image_crop_strategy import ImageCropStrategy
from .image_decode_strategy import ImageDecodeStrategy
from .image_pad_to_multiple_strategy import ImagePadToMultipleStrategy
from .image_perspective_crop_strategy import ImagePerspectiveCropStrategy
from .image_resize_strategy import ImageResizeStrategy
from .image_resize_pad_strategy import ImageResizePadStrategy
from .registry import TransformationRegistry
from .tensor_channel_order_strategy import TensorChannelOrderStrategy
from .tensor_layout_strategy import TensorLayoutStrategy
from .tensor_normalize_strategy import TensorNormalizeStrategy


def default_transformation_registry():
    return TransformationRegistry(
        [
            ImageDecodeStrategy(),
            ImageCropStrategy(),
            ImagePerspectiveCropStrategy(),
            ImagePadToMultipleStrategy(),
            ImageResizeStrategy(),
            ImageResizePadStrategy(),
            TensorChannelOrderStrategy(),
            TensorLayoutStrategy(),
            TensorNormalizeStrategy(),
        ]
    )
