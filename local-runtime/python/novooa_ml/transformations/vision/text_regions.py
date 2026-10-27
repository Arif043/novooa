import math

from novooa_ml.transformations.kinds import REGIONS, TENSOR
from novooa_ml.transformations.schema import Integer, Number
from novooa_ml.transformations.strategy import TransformationStrategy

from .mask_regions import regions_from_mask


class TextRegionsStrategy(TransformationStrategy):
    """Leitet aus einer Wahrscheinlichkeitsmaske bewertete Textregionen ab (DB-Nachverarbeitung).

    Schwelle, Dilatation, Mindestscore wie bei DBNet/PP-OCR; `unclipRatio` vergrößert jede Region
    wie das „Unclip“ der Referenz um `Fläche × unclipRatio / Umfang` je Seite, weil das Modell nur
    den Kern einer Textzeile markiert. `padding` fügt danach einen festen Rand hinzu.
    """

    accepts = (TENSOR,)
    produces = REGIONS
    parameters = {
        "threshold": Number(minimum=0, maximum=1, optional=True, default=0.3),
        "minimumPixels": Integer(minimum=0, optional=True, default=1),
        "minimumScore": Number(minimum=0, maximum=1, optional=True, default=0),
        "dilationWidth": Integer(minimum=1, optional=True, default=1),
        "dilationHeight": Integer(minimum=1, optional=True, default=1),
        "padding": Integer(minimum=0, optional=True, default=0),
        "unclipRatio": Number(minimum=0, optional=True, default=0),
    }

    @property
    def transformation_type(self):
        return "mask.textRegions"

    def transform(self, value, parameters, context):
        probability = probability_mask(value)
        threshold = probability_parameter(parameters, "threshold", 0.3, 0, 1)
        minimum_pixels = nonnegative_integer(parameters.get("minimumPixels", 1), "minimumPixels")
        minimum_score = probability_parameter(parameters, "minimumScore", 0, 0, 1)
        dilation_width = positive_integer(parameters.get("dilationWidth", 1), "dilationWidth")
        dilation_height = positive_integer(parameters.get("dilationHeight", 1), "dilationHeight")
        padding = nonnegative_integer(parameters.get("padding", 0), "padding")
        unclip_ratio = probability_parameter(parameters, "unclipRatio", 0, 0, math.inf)
        mask = probability >= threshold
        merged = dilate(mask, dilation_width, dilation_height, context.numpy)
        return text_regions(
            probability, mask, merged, minimum_pixels, minimum_score, (unclip_ratio, padding)
        )


def probability_mask(value):
    if value.ndim < 2 or any(size != 1 for size in value.shape[:-2]):
        raise ValueError("mask.textRegions erwartet eine einzelne zweidimensionale Maske.")
    return value.reshape(value.shape[-2], value.shape[-1])


def dilate(mask, width, height, numpy):
    radius_x = width // 2
    radius_y = height // 2
    padded = numpy.pad(mask, ((radius_y, radius_y), (radius_x, radius_x)))
    expanded = numpy.zeros_like(mask, dtype=bool)
    for offset_y in range(height):
        for offset_x in range(width):
            expanded |= padded[offset_y:offset_y + mask.shape[0], offset_x:offset_x + mask.shape[1]]
    return expanded


def text_regions(probability, mask, merged, minimum_pixels, minimum_score, expansion):
    regions = []
    for region in regions_from_mask(merged, 1):
        candidate = region_with_score(region, probability, mask, expansion)
        if candidate["pixelCount"] < minimum_pixels:
            continue
        if candidate["score"] < minimum_score:
            continue
        regions.append(candidate)
    return sorted(regions, key=lambda item: (item["bounds"]["top"], item["bounds"]["left"]))


def region_with_score(region, probability, mask, expansion):
    bounds = region["bounds"]
    left, top, width, height = (
        bounds["left"], bounds["top"], bounds["width"], bounds["height"]
    )
    right, bottom = left + width, top + height
    source = mask[top:bottom, left:right]
    values = probability[top:bottom, left:right][source]
    score = float(values.mean()) if values.size else 0
    unclip_ratio, padding = expansion
    return {
        "bounds": padded_bounds(unclipped(bounds, unclip_ratio), padding, probability.shape),
        "pixelCount": int(source.sum()),
        "score": score,
    }


def unclipped(bounds, ratio):
    """Vergrößert die Box je Seite um Fläche × ratio / Umfang (DB-Unclip, für Rechtecke exakt)."""
    width, height = bounds["width"], bounds["height"]
    distance = width * height * ratio / (2 * (width + height))
    left, top = math.floor(bounds["left"] - distance), math.floor(bounds["top"] - distance)
    right = math.ceil(bounds["left"] + width + distance)
    bottom = math.ceil(bounds["top"] + height + distance)
    return {"left": left, "top": top, "width": right - left, "height": bottom - top}


def padded_bounds(bounds, padding, shape):
    height, width = shape
    left = max(0, bounds["left"] - padding)
    top = max(0, bounds["top"] - padding)
    right = min(width, bounds["left"] + bounds["width"] + padding)
    bottom = min(height, bounds["top"] + bounds["height"] + padding)
    return {"left": left, "top": top, "width": right - left, "height": bottom - top}


def probability_parameter(parameters, name, fallback, minimum, maximum):
    value = parameters.get(name, fallback)
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"mask.textRegions benötigt eine Zahl für {name}.")
    if value < minimum or value > maximum:
        raise ValueError(f"mask.textRegions benötigt {name} zwischen {minimum} und {maximum}.")
    return float(value)


def nonnegative_integer(value, name):
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"mask.textRegions benötigt eine nichtnegative Ganzzahl für {name}.")
    return value


def positive_integer(value, name):
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValueError(f"mask.textRegions benötigt eine positive Ganzzahl für {name}.")
    return value
