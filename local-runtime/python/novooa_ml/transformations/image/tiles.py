from novooa_ml.transformations.geometry import lose_geometry
from novooa_ml.transformations.kinds import IMAGE, TENSOR
from novooa_ml.transformations.parameters import is_integer
from novooa_ml.transformations.schema import Integer
from novooa_ml.transformations.strategy import TransformationStrategy
from novooa_ml.transformations.travelling_metadata import TILES
from novooa_ml.transformations.values import as_tensor, require_image


class ImageTilesStrategy(TransformationStrategy):
    """Zerlegt ein Bild in quadratische Kacheln und rechnet sie als Batch `[N, size, size, C]`.

    Für Modelle mit fester oder begrenzter Eingabegröße (Hochskalieren, Segmentierung großer
    Bilder). Benachbarte Kacheln überlappen um `overlap` Pixel; der Rand wird mit den Randpixeln
    aufgefüllt. Das Raster reist in den Metadaten, `tensor.untile` setzt das Ergebnis zusammen.
    """

    accepts = (IMAGE,)
    produces = TENSOR
    parameters = {"size": Integer(minimum=1), "overlap": Integer(minimum=0, optional=True, default=0)}

    @property
    def transformation_type(self):
        return "image.tiles"

    def transform(self, value, parameters, context):
        numpy = context.numpy
        image = require_image(value, self.transformation_type, context)
        size, overlap = parameters.get("size"), parameters.get("overlap", 0)
        if not is_integer(size) or not is_integer(overlap) or size <= 0 or not 0 <= overlap < size:
            raise ValueError("image.tiles benötigt size > 0 und 0 ≤ overlap < size.")
        pixels = as_tensor(image, context)
        height, width = pixels.shape[:2]
        step = size - overlap
        rows, columns = tile_count(height, size, step), tile_count(width, size, step)
        canvas = numpy.pad(pixels, ((0, (rows - 1) * step + size - height), (0, (columns - 1) * step + size - width), (0, 0)), mode="edge")
        tiles = [canvas[row * step:row * step + size, column * step:column * step + size] for row in range(rows) for column in range(columns)]
        context.metadata[TILES] = {"rows": rows, "columns": columns, "size": size, "overlap": overlap, "width": width, "height": height}
        # Koordinaten einzelner Kacheln lassen sich nicht ins Original zurückrechnen; dafür ist tensor.untile da.
        lose_geometry(context)
        return numpy.stack(tiles)


def tile_count(length, size, step):
    """So viele Kacheln, dass sie die Länge abdecken; mindestens eine."""
    return max(1, -(-(length - size) // step) + 1) if length > size else 1
