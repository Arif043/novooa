"""Gemeinsame Helfer für Bildtransformationen, die auf eine Zielfläche auffüllen."""


def alignment_for(value):
    if value not in ("topLeft", "center"):
        raise ValueError("image.resizePad unterstützt topLeft oder center.")
    return value


def background_for(value):
    if not isinstance(value, int) or value < 0 or value > 255:
        raise ValueError("image.resizePad benötigt eine Hintergrundfarbe zwischen 0 und 255.")
    return value
