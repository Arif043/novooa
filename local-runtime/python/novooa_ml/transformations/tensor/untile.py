from novooa_ml.transformations.kinds import TENSOR
from novooa_ml.transformations.parameters import number
from novooa_ml.transformations.schema import Choice, Number, Text
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.travelling_metadata import TILES
from novooa_ml.transformations.values import as_tensor


class TensorUntileStrategy(TransformationStrategy):
    """Setzt die Kacheln eines Batches nach dem Raster von `image.tiles` wieder zu einem Bild zusammen.

    Das Raster kommt aus den Metadaten des Eingangs `input`. `scale` ist der Vergrößerungsfaktor
    des Modells (z. B. 4 bei Real-ESRGAN, 1 bei Segmentierung). Jede Kachel steuert nur ihren
    mittleren Teil bei — überlappende Ränder werden halbiert —, Auffüllung wird abgeschnitten.
    Ergebnis `[H × scale, W × scale, C]`; mit `layout: channelsFirst` werden `[N, C, h, w]` gelesen.
    """

    accepts = (TENSOR,)
    produces = TENSOR
    parameters = {
        "input": Text(),
        "scale": Number(minimum=0, optional=True, default=1),
        "layout": Choice("channelsFirst", "channelsLast", optional=True, default="channelsLast"),
    }

    @property
    def transformation_type(self):
        return "tensor.untile"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        grid = context.input_metadata(parameters.get("input"), TILES, self.transformation_type, "kein Kachelraster (image.tiles fehlt)")
        tiles = numpy.asarray(as_tensor(value, context))
        if parameters.get("layout", "channelsLast") == "channelsFirst" and tiles.ndim == 4:
            tiles = numpy.moveaxis(tiles, 1, -1)
        scale = number(parameters.get("scale", 1), self.transformation_type, "scale")
        self.validate(tiles, grid, scale)
        return assembled(numpy, tiles, grid, scale)[:round(grid["height"] * scale), :round(grid["width"] * scale)]

    def validate(self, tiles, grid, scale):
        if tiles.ndim != 4:
            raise ValueError("tensor.untile erwartet Kacheln [N, h, w, C].")
        if tiles.shape[0] != grid["rows"] * grid["columns"]:
            raise ValueError(f"tensor.untile: {tiles.shape[0]} Kacheln passen nicht zum Raster {grid['rows']} × {grid['columns']}.")
        expected = round(grid["size"] * scale)
        if tiles.shape[1] != expected or tiles.shape[2] != expected:
            raise ValueError(f"tensor.untile: Kacheln {tiles.shape[1]} × {tiles.shape[2]} passen nicht zu size × scale = {expected}.")


def assembled(numpy, tiles, grid, scale):
    """Legt den eigenen Bereich jeder Kachel an seine Stelle im vergrößerten Gesamtbild."""
    height = round(owned_end(grid["rows"] - 1, grid, grid["rows"]) * scale)
    width = round(owned_end(grid["columns"] - 1, grid, grid["columns"]) * scale)
    canvas = numpy.zeros((height, width, tiles.shape[-1]), dtype=tiles.dtype)
    for index, tile in enumerate(tiles):
        row, column = divmod(index, grid["columns"])
        top, bottom = (round(edge * scale) for edge in owned(row, grid, grid["rows"]))
        left, right = (round(edge * scale) for edge in owned(column, grid, grid["columns"]))
        origin_y, origin_x = round(row * step_of(grid) * scale), round(column * step_of(grid) * scale)
        canvas[top:bottom, left:right] = tile[top - origin_y:bottom - origin_y, left - origin_x:right - origin_x]
    return canvas


def step_of(grid):
    return grid["size"] - grid["overlap"]


def owned(index, grid, count):
    """Der Bereich, den eine Kachel im zusammengesetzten Bild beiträgt (in Eingangspixeln)."""
    start = index * step_of(grid) + (grid["overlap"] // 2 if index > 0 else 0)
    return start, owned_end(index, grid, count)


def owned_end(index, grid, count):
    if index < count - 1:
        return (index + 1) * step_of(grid) + grid["overlap"] // 2
    return index * step_of(grid) + grid["size"]
