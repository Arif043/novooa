"""Phonem-IDs für Piper, gemeinsam genutzt von Phonemen und Phonemlänge."""

from .phonemizer import phonemize


def phoneme_ids(text, parameters, numpy):
    language = parameters.get("language")
    phoneme_map = parameters.get("phonemeIdMap")
    if not isinstance(language, str) or not language:
        raise ValueError("Die Piper-Transformation benötigt eine Sprache.")
    if not isinstance(phoneme_map, dict):
        raise ValueError("Die Piper-Transformation benötigt eine Phonemzuordnung.")
    symbols = ["^", *phonemize(text, language, "Piper"), "$"]
    try:
        return numpy.asarray([phoneme_id(phoneme_map, symbol) for symbol in symbols], dtype=numpy.int64)
    except KeyError as error:
        raise ValueError(f"Das Piper-Modell unterstützt das Phonem {error.args[0]!r} nicht.") from error


def phoneme_id(phoneme_map, symbol):
    value = phoneme_map.get(symbol)
    if isinstance(value, list) and len(value) == 1 and isinstance(value[0], int):
        return value[0]
    if isinstance(value, int):
        return value
    raise KeyError(symbol)
