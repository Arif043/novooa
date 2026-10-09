from novooa_ml.transformations.kinds import DETECTIONS, REGIONS, SAME
from novooa_ml.transformations.schema import Boolean, Text
from novooa_ml.transformations.strategy import TransformationStrategy


class GeometryToSourceStrategy(TransformationStrategy):
    """Rechnet Regionen (`bounds`) und Erkennungen (`box`) in Koordinaten des Originalbildes zurück.

    Grundlage ist die Geometrie, die der Eingang `input` beim Skalieren, Auffüllen und
    Zuschneiden aufgezeichnet hat. Mit `clip` (Standard) werden Werte auf das Bild begrenzt.
    """

    accepts = (REGIONS, DETECTIONS)
    produces = SAME
    parameters = {"input": Text(), "clip": Boolean(optional=True, default=True)}

    @property
    def transformation_type(self):
        return "geometry.toSource"

    def transform(self, value, parameters, context):
        geometry = context.input_geometry(parameters.get("input"), self.transformation_type)
        clip = parameters.get("clip", True)
        if not isinstance(value, list):
            raise ValueError("geometry.toSource erwartet eine Liste von Regionen oder Erkennungen.")
        return [mapped_item(item, geometry, clip) for item in value]


def mapped_item(item, geometry, clip):
    if isinstance(item, dict) and isinstance(item.get("box"), dict):
        return {**item, "box": mapped_box(item["box"], geometry, clip)}
    if isinstance(item, dict) and isinstance(item.get("bounds"), dict):
        return {**item, "bounds": mapped_bounds(item["bounds"], geometry, clip)}
    raise ValueError("geometry.toSource erwartet Einträge mit box oder bounds.")


def mapped_box(box, geometry, clip):
    left, right = (source_x(box[key], geometry, clip) for key in ("left", "right"))
    top, bottom = (source_y(box[key], geometry, clip) for key in ("top", "bottom"))
    return {**box, "left": left, "top": top, "right": right, "bottom": bottom}


def mapped_bounds(bounds, geometry, clip):
    left = source_x(bounds["left"], geometry, clip)
    top = source_y(bounds["top"], geometry, clip)
    right = source_x(bounds["left"] + bounds["width"], geometry, clip)
    bottom = source_y(bounds["top"] + bounds["height"], geometry, clip)
    return {**bounds, "left": round(left), "top": round(top), "width": round(right - left), "height": round(bottom - top)}


def source_x(value, geometry, clip):
    return within((value - geometry["offsetX"]) / geometry["scaleX"], geometry["sourceWidth"], clip)


def source_y(value, geometry, clip):
    return within((value - geometry["offsetY"]) / geometry["scaleY"], geometry["sourceHeight"], clip)


def within(value, size, clip):
    return float(min(max(value, 0), size)) if clip else float(value)
