from novooa_ml.transformations.kinds import REGIONS
from novooa_ml.transformations.schema import Number
from novooa_ml.transformations.strategy import TransformationStrategy


class ScaleBoundsStrategy(TransformationStrategy):
    """Rechnet Regionen vom Maskenraster in Bildkoordinaten zurück."""

    accepts = (REGIONS,)
    produces = REGIONS
    parameters = {"scaleX": Number(minimum=0), "scaleY": Number(minimum=0), "offsetX": Number(optional=True, default=0), "offsetY": Number(optional=True, default=0)}

    @property
    def transformation_type(self):
        return "geometry.scaleBounds"

    def transform(self, value, parameters, context):
        scale_x = positive_number(parameters.get("scaleX"), "scaleX")
        scale_y = positive_number(parameters.get("scaleY"), "scaleY")
        offset_x = number_or_default(parameters.get("offsetX"), 0, "offsetX")
        offset_y = number_or_default(parameters.get("offsetY"), 0, "offsetY")
        if not isinstance(value, list):
            raise ValueError("geometry.scaleBounds erwartet eine Liste von Regionen.")
        return [scale_region(region, scale_x, scale_y, offset_x, offset_y) for region in value]


def scale_region(region, scale_x, scale_y, offset_x, offset_y):
    if not isinstance(region, dict) or not isinstance(region.get("bounds"), dict):
        raise ValueError("geometry.scaleBounds erwartet Regionen mit bounds.")
    bounds = region["bounds"]
    scaled = {
        "left": position(bounds.get("left"), scale_x, offset_x, "left"),
        "top": position(bounds.get("top"), scale_y, offset_y, "top"),
        "width": size(bounds.get("width"), scale_x, "width"),
        "height": size(bounds.get("height"), scale_y, "height"),
    }
    return {**region, "bounds": scaled}


def position(value, scale, offset, name):
    return round(number(value, name) * scale + offset)


def size(value, scale, name):
    return max(1, round(number(value, name) * scale))


def positive_number(value, name):
    numeric = number(value, name)
    if numeric <= 0:
        raise ValueError(f"geometry.scaleBounds benötigt einen positiven Wert für {name}.")
    return numeric


def number_or_default(value, default, name):
    return default if value is None else number(value, name)


def number(value, name):
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise ValueError(f"geometry.scaleBounds benötigt eine Zahl für {name}.")
    return value
