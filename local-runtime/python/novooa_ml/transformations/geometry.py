"""Wie die Eingangsschritte ein Bild räumlich verändert haben.

`context.metadata["geometry"]` beschreibt die Abbildung vom Quellbild ins Modellbild:
`modell = quelle × scale + offset` je Achse. Ausgangstransformationen rechnen damit Boxen und
Masken in Koordinaten des Originalbildes zurück. Nicht umkehrbare Schritte (perspektivischer
Zuschnitt) setzen die Geometrie auf None.
"""

KEY = "geometry"


def start_geometry(context, image):
    """Identität für das Quellbild; der Eingangs-Worker ruft das für Bildquellen auf."""
    width, height = image.size
    context.metadata[KEY] = {
        "sourceWidth": width, "sourceHeight": height,
        "scaleX": 1.0, "scaleY": 1.0, "offsetX": 0.0, "offsetY": 0.0,
    }


def scale_geometry(context, factor_x, factor_y):
    geometry = context.metadata.get(KEY)
    if geometry is None:
        return
    geometry.update({
        "scaleX": geometry["scaleX"] * factor_x, "scaleY": geometry["scaleY"] * factor_y,
        "offsetX": geometry["offsetX"] * factor_x, "offsetY": geometry["offsetY"] * factor_y,
    })


def resize_geometry(context, before, after):
    """Skalierung aus der Bildgröße vor und nach einem Schritt."""
    scale_geometry(context, after[0] / before[0], after[1] / before[1])


def shift_geometry(context, delta_x, delta_y):
    geometry = context.metadata.get(KEY)
    if geometry is None:
        return
    geometry["offsetX"] += delta_x
    geometry["offsetY"] += delta_y


def restart_geometry(context, image):
    """Der Schritt macht sein Ergebnis zur neuen Quelle (z. B. ein nach EXIF gedrehtes Foto)."""
    if KEY in context.metadata:
        start_geometry(context, image)


def lose_geometry(context):
    """Nach einem nicht umkehrbaren Schritt lässt sich nichts zurückrechnen."""
    if KEY in context.metadata:
        context.metadata[KEY] = None
