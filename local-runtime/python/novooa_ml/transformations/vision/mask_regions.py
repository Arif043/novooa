"""Zusammenhängende Regionen einer Binärmaske, gemeinsam genutzt von Masken-Transformationen."""


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
