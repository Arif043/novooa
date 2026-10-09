from novooa_ml.transformations.kinds import REGIONS, TENSOR
from novooa_ml.transformations.schema import Integer
from novooa_ml.transformations.strategy import TransformationStrategy

from .mask_regions import regions_from_mask


class ConnectedComponentsStrategy(TransformationStrategy):
    """Liefert zusammenhängende Regionen einer Maske als `{bounds, pixelCount}`."""

    accepts = (TENSOR,)
    produces = REGIONS
    parameters = {"minimumPixels": Integer(minimum=0, optional=True, default=1)}

    @property
    def transformation_type(self):
        return "mask.connectedComponents"

    def transform(self, value, parameters, context):
        if value.ndim < 2 or any(size != 1 for size in value.shape[:-2]):
            raise ValueError("mask.connectedComponents erwartet eine einzelne zweidimensionale Maske.")
        minimum = parameters.get("minimumPixels", 1)
        if not isinstance(minimum, int) or minimum < 0:
            raise ValueError("minimumPixels muss eine nichtnegative ganze Zahl sein.")
        mask = value.reshape(value.shape[-2], value.shape[-1]).astype(bool)
        return regions_from_mask(mask, minimum)
