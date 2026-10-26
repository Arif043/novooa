"""Wertarten, die durch eine Transformationspipeline fließen.

Jede Strategie deklariert, welche Arten sie annimmt (`accepts`) und welche sie liefert
(`produces`). Daraus folgt, wo eine Transformation stehen darf — nicht aus der Richtung.
"""

IMAGE = "image"
AUDIO = "audio"
TEXT = "text"
DATETIME = "datetime"
NUMBER = "number"
JSON = "json"
TENSOR = "tensor"
REGIONS = "regions"
DETECTIONS = "detections"
# Liste `{index, x, y, score?}` in Modellpixeln, z. B. Körper- oder Gesichtspunkte.
KEYPOINTS = "keypoints"
JSON_RESULT = "json-result"
AUDIO_FILE = "audioFile"
IMAGE_FILE = "imageFile"
ANY = "*"
# Als `produces`: Das Ergebnis behält die Wertart der Eingabe (z. B. Regionen bleiben Regionen).
SAME = "same"

KINDS = (
    IMAGE, AUDIO, TEXT, DATETIME, NUMBER, JSON, TENSOR, REGIONS, DETECTIONS, KEYPOINTS, JSON_RESULT, AUDIO_FILE,
    IMAGE_FILE,
)

# Bilder und Audiosignale lassen sich ohne eigenen Schritt als Tensor lesen (`as_tensor`).
CONVERTIBLE_TO_TENSOR = (IMAGE, AUDIO)

SOURCE_KINDS = {
    "image": IMAGE,
    "audio": AUDIO,
    "text": TEXT,
    "datetime": DATETIME,
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
