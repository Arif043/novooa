"""Gemeinsames der Box-Dekodierung: Zeilen lesen, Spalten der Box, Größenkodierung."""

from novooa_ml.transformations.parameters import column_index
from novooa_ml.transformations.schema import Choice, Integer, Record

from .detection_rows import CENTER_KEYS

BOX = Record({name: Integer(minimum=0) for name in CENTER_KEYS})
SIZE_ENCODING = Choice("exp", "linear", optional=True, default="exp")


def decoding_rows(numpy, tensor, transformation_type):
    """`[1, N, V]` oder `[N, V]` → float32-Kopie `[N, V]`; die Dekodierung verändert die Eingabe nicht."""
    rows = numpy.array(tensor, dtype=numpy.float32)
    while rows.ndim > 2 and rows.shape[0] == 1:
        rows = rows[0]
    if rows.ndim != 2:
        raise ValueError(f"{transformation_type} erwartet [zeilen, werte] oder [1, zeilen, werte].")
    return rows


def box_columns(parameters, width, transformation_type):
    box = parameters.get("box")
    if not isinstance(box, dict):
        raise ValueError(f"{transformation_type} benötigt box mit centerX, centerY, width und height.")
    columns = {key: column_index(box.get(key)) for key in CENTER_KEYS}
    if max(columns.values()) >= width:
        raise ValueError(f"{transformation_type}: Eine Box-Spalte liegt außerhalb der Tensorbreite {width}.")
    return columns


def decoded_size(numpy, raw, encoding, transformation_type):
    if encoding == "exp":
        return numpy.exp(raw)
    if encoding == "linear":
        return raw
    raise ValueError(f"{transformation_type}: sizeEncoding erwartet exp oder linear.")
