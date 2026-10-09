"""Wandelt eine Eingangsquelle in den Startwert ihrer Pipeline."""

import base64
import io
from datetime import datetime, timezone

from novooa_ml.transformations.values import AudioSignal

from .wav_decoder import decode_wav


def initial_value(source, image_module):
    source_type = source["type"]
    if source_type in ("text", "number", "json", "boolean"):
        return source["value"]
    if source_type == "datetime":
        return parsed_datetime(source["value"])
    if source_type == "image":
        return image_module.open(io.BytesIO(source_bytes(source)))
    if source_type == "audio":
        samples, sample_rate = decode_wav(source_bytes(source), source.get("contentType", ""))
        return AudioSignal(samples, sample_rate)
    raise ValueError(
        f"Die Eingabequelle {source_type} wird von der lokalen Transformation nicht unterstützt."
    )


def parsed_datetime(value):
    """ISO-8601-Text → zeitzonenbewusstes datetime; Angaben ohne Versatz gelten als UTC."""
    try:
        moment = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except (AttributeError, TypeError, ValueError) as error:
        raise ValueError(f"{value!r} ist kein gültiges ISO-8601-Datum.") from error
    return moment if moment.tzinfo is not None else moment.replace(tzinfo=timezone.utc)


def source_bytes(source):
    return base64.b64decode(source["dataBase64"], validate=True)
