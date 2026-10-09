"""Wandelt eine Eingangsquelle in den Startwert ihrer Pipeline."""

import base64
import io

from novooa_ml.transformations.values import AudioSignal

from .wav_decoder import decode_wav


def initial_value(source, image_module):
    source_type = source["type"]
    if source_type in ("text", "number", "json", "boolean"):
        return source["value"]
    if source_type == "image":
        return image_module.open(io.BytesIO(source_bytes(source)))
    if source_type == "audio":
        samples, sample_rate = decode_wav(source_bytes(source), source.get("contentType", ""))
        return AudioSignal(samples, sample_rate)
    raise ValueError(
        f"Die Eingabequelle {source_type} wird von der lokalen Transformation nicht unterstützt."
    )


def source_bytes(source):
    return base64.b64decode(source["dataBase64"], validate=True)
