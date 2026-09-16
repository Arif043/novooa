from .registry import OutputTransformationStrategy


class ConnectedComponentsStrategy(OutputTransformationStrategy):
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


class NonMaximumSuppressionStrategy(OutputTransformationStrategy):
    @property
    def transformation_type(self):
        return "tensor.nonMaximumSuppression"

    def transform(self, value, parameters, context):
        if value.ndim != 2:
            raise ValueError("tensor.nonMaximumSuppression erwartet [erkennungen, werte].")
        box = parameters.get("box")
        if not isinstance(box, dict):
            raise ValueError("tensor.nonMaximumSuppression benötigt box.")
        indexes = {key: required_index(box.get(key)) for key in ("left", "top", "right", "bottom")}
        score_index = required_index(parameters.get("scoreIndex"))
        if max(*indexes.values(), score_index) >= value.shape[1]:
            raise ValueError("Ein Erkennungsindex liegt außerhalb der Tensorbreite.")
        threshold = numeric_parameter(parameters.get("scoreThreshold"), float("-inf"))
        iou_threshold = numeric_parameter(parameters.get("iouThreshold"), 0.5)
        if iou_threshold < 0 or iou_threshold > 1:
            raise ValueError("iouThreshold liegt außerhalb des erlaubten Bereichs.")
        detections = [
            detection(row, index, indexes, score_index)
            for index, row in enumerate(value)
            if float(row[score_index]) >= threshold
        ]
        return suppress_overlaps(detections, iou_threshold)


def regions_from_mask(mask, minimum_pixels):
    height, width = mask.shape
    visited = set()
    regions = []
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if not mask[y, x] or index in visited:
                continue
            region = region_from(mask, x, y, visited)
            if region["pixelCount"] >= minimum_pixels:
                regions.append(region)
    return regions


def region_from(mask, first_x, first_y, visited):
    height, width = mask.shape
    pending = [(first_x, first_y)]
    left, right, top, bottom, pixel_count = width, 0, height, 0, 0
    while pending:
        x, y = pending.pop()
        index = y * width + x
        if index in visited or not mask[y, x]:
            continue
        visited.add(index)
        left, right = min(left, x), max(right, x)
        top, bottom = min(top, y), max(bottom, y)
        pixel_count += 1
        pending.extend(neighbours(x, y, width, height))
    return {
        "bounds": {"left": left, "top": top, "width": right - left + 1, "height": bottom - top + 1},
        "pixelCount": pixel_count,
    }


def neighbours(x, y, width, height):
    return [
        (next_x, next_y)
        for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1))
        if 0 <= next_x < width and 0 <= next_y < height
    ]


def detection(row, index, box_indexes, score_index):
    box = {key: float(row[value]) for key, value in box_indexes.items()}
    if box["right"] < box["left"] or box["bottom"] < box["top"]:
        raise ValueError("Eine Erkennungsbox ist ungültig.")
    return {"index": index, "score": float(row[score_index]), "box": box}


def suppress_overlaps(detections, threshold):
    accepted = []
    for candidate in sorted(detections, key=lambda item: item["score"], reverse=True):
        if all(iou(candidate["box"], item["box"]) <= threshold for item in accepted):
            accepted.append(candidate)
    return accepted


def iou(left, right):
    overlap_width = max(0, min(left["right"], right["right"]) - max(left["left"], right["left"]))
    overlap_height = max(0, min(left["bottom"], right["bottom"]) - max(left["top"], right["top"]))
    overlap = overlap_width * overlap_height
    left_area = (left["right"] - left["left"]) * (left["bottom"] - left["top"])
    right_area = (right["right"] - right["left"]) * (right["bottom"] - right["top"])
    return overlap / (left_area + right_area - overlap or 1)


def required_index(value):
    if not isinstance(value, int) or value < 0:
        raise ValueError("Ein Spaltenindex muss eine nichtnegative ganze Zahl sein.")
    return value


def numeric_parameter(value, fallback):
    if value is None:
        return fallback
    if not isinstance(value, (int, float)):
        raise ValueError("Der Transformationsparameter ist ungültig.")
    return value
