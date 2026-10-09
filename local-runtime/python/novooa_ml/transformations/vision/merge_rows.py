from novooa_ml.transformations.kinds import REGIONS
from novooa_ml.transformations.strategy import TransformationStrategy


class MergeRowsStrategy(TransformationStrategy):
    """Fasst Regionen mit ausreichender vertikaler Überlappung zu Zeilen zusammen."""

    accepts = (REGIONS,)
    produces = REGIONS

    @property
    def transformation_type(self):
        return "geometry.mergeRows"

    def transform(self, value, parameters, context):
        if not isinstance(value, list):
            raise ValueError("geometry.mergeRows erwartet eine Liste von Regionen.")
        overlap = overlap_parameter(parameters.get("minimumVerticalOverlap", 0.5))
        return merged_rows(value, overlap)


def merged_rows(regions, minimum_overlap):
    rows = []
    for region in sorted(validated_regions(regions), key=sort_key):
        if rows and overlaps_row(region, rows[-1], minimum_overlap):
            rows[-1] = merge_row(rows[-1], region)
        else:
            rows.append(row_for(region))
    return rows


def validated_regions(regions):
    return [validated_region(region) for region in regions]


def validated_region(region):
    if not isinstance(region, dict) or not isinstance(region.get("bounds"), dict):
        raise ValueError("geometry.mergeRows erwartet Regionen mit bounds.")
    bounds = region["bounds"]
    for name in ("left", "top", "width", "height"):
        if not isinstance(bounds.get(name), int) or bounds[name] < 0:
            raise ValueError("geometry.mergeRows benötigt ganzzahlige bounds.")
    if bounds["width"] == 0 or bounds["height"] == 0:
        raise ValueError("geometry.mergeRows benötigt nichtleere bounds.")
    return region


def sort_key(region):
    bounds = region["bounds"]
    return bounds["top"], bounds["left"]


def overlaps_row(region, row, minimum_overlap):
    left = region["bounds"]
    right = row["bounds"]
    overlap = max(0, min(left["top"] + left["height"], right["top"] + right["height"]) - max(left["top"], right["top"]))
    return overlap / min(left["height"], right["height"]) >= minimum_overlap


def row_for(region):
    return {
        "bounds": dict(region["bounds"]),
        "pixelCount": region.get("pixelCount", 0),
        "score": region.get("score", 0),
        "memberCount": 1,
    }


def merge_row(row, region):
    bounds = union_bounds(row["bounds"], region["bounds"])
    left_count = row["pixelCount"]
    right_count = region.get("pixelCount", 0)
    total = left_count + right_count
    score = weighted_score(row["score"], left_count, region.get("score", 0), right_count)
    return {
        "bounds": bounds,
        "pixelCount": total,
        "score": score,
        "memberCount": row["memberCount"] + 1,
    }


def union_bounds(left, right):
    start_x = min(left["left"], right["left"])
    start_y = min(left["top"], right["top"])
    end_x = max(left["left"] + left["width"], right["left"] + right["width"])
    end_y = max(left["top"] + left["height"], right["top"] + right["height"])
    return {"left": start_x, "top": start_y, "width": end_x - start_x, "height": end_y - start_y}


def weighted_score(left_score, left_count, right_score, right_count):
    total = left_count + right_count
    if total == 0:
        return max(left_score, right_score)
    return (left_score * left_count + right_score * right_count) / total


def overlap_parameter(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or value <= 0 or value > 1:
        raise ValueError("geometry.mergeRows benötigt minimumVerticalOverlap zwischen 0 und 1.")
    return float(value)
