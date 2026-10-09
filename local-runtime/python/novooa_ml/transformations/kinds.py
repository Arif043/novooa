"""Wertarten, die durch eine Transformationspipeline fließen.

Jede Strategie deklariert, welche Arten sie annimmt (`accepts`) und welche sie liefert
(`produces`). Daraus folgt, wo eine Transformation stehen darf — nicht aus der Richtung.
"""

IMAGE = "image"
AUDIO = "audio"
TEXT = "text"
NUMBER = "number"
JSON = "json"
TENSOR = "tensor"
REGIONS = "regions"
JSON_RESULT = "json-result"
AUDIO_FILE = "audioFile"
ANY = "*"

KINDS = (IMAGE, AUDIO, TEXT, NUMBER, JSON, TENSOR, REGIONS, JSON_RESULT, AUDIO_FILE)

# Bilder und Audiosignale lassen sich ohne eigenen Schritt als Tensor lesen (`as_tensor`).
CONVERTIBLE_TO_TENSOR = (IMAGE, AUDIO)

SOURCE_KINDS = {
    "image": IMAGE,
    "audio": AUDIO,
    "text": TEXT,
    "number": NUMBER,
    "json": JSON,
    "boolean": JSON,
}


def accepts(accepted, kind):
    if ANY in accepted or kind in accepted:
        return True
    return TENSOR in accepted and kind in CONVERTIBLE_TO_TENSOR


def is_tensor_ready(kind):
    return kind == TENSOR or kind in CONVERTIBLE_TO_TENSOR
