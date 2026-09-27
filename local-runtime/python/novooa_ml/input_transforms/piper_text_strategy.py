from .strategy import InputTransformStrategy


class PiperPhonemesStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "text.piperPhonemes"

    def transform(self, context, parameters):
        context.tensor = phoneme_ids(context, parameters)


class PiperPhonemeLengthStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "text.piperPhonemeLength"

    def transform(self, context, parameters):
        context.tensor = context.numpy.asarray([len(phoneme_ids(context, parameters))], dtype=context.numpy.int64)


def phoneme_ids(context, parameters):
    language = parameters.get("language")
    phoneme_map = parameters.get("phonemeIdMap")
    if not isinstance(language, str) or not language:
        raise ValueError("Die Piper-Transformation benötigt eine Sprache.")
    if not isinstance(phoneme_map, dict):
        raise ValueError("Die Piper-Transformation benötigt eine Phonemzuordnung.")
    pronunciation = phonemize(context.text, language)
    symbols = ["^", *pronunciation, "$"]
    try:
        return context.numpy.asarray([phoneme_id(phoneme_map, symbol) for symbol in symbols], dtype=context.numpy.int64)
    except KeyError as error:
        raise ValueError(f"Das Piper-Modell unterstützt das Phonem {error.args[0]!r} nicht.") from error


def phonemize(text, language):
    try:
        from phonemizer import phonemize as phonemize_text
    except ImportError as error:
        raise RuntimeError("Die Piper-Texttransformation benötigt phonemizer und espeak-ng.") from error
    return phonemize_text(text, language=language, backend="espeak", strip=True, preserve_punctuation=True, with_stress=True)


def phoneme_id(phoneme_map, symbol):
    value = phoneme_map.get(symbol)
    if isinstance(value, list) and len(value) == 1 and isinstance(value[0], int):
        return value[0]
    if isinstance(value, int):
        return value
    raise KeyError(symbol)
