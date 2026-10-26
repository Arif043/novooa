"""Was eine Eingangspipeline über ihre Quelle weiß und dem Ausgang mitgibt.

Die Runtime reicht diese Metadaten unverändert vom Eingangstensor an die Inferenz weiter. Interne
Schlüssel wie das Tensor-Layout bleiben in der Pipeline.
"""

GEOMETRY = "geometry"
TILES = "tiles"
SOURCE_IMAGE = "sourceImage"

TRAVELLING_KEYS = (GEOMETRY, TILES, SOURCE_IMAGE)


def travelling_metadata(context):
    return {key: context.metadata[key] for key in TRAVELLING_KEYS if key in context.metadata}
