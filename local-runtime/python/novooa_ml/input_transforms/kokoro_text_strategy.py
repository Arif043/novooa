from .strategy import InputTransformStrategy


class KokoroTokensStrategy(InputTransformStrategy):
    @property
    def transformation_type(self):
        return "text.kokoroTokens"

    def transform(self, context, parameters):
        tokens = kokoro_token_ids(context.text, parameters)
        context.tensor = context.numpy.asarray([[0, *tokens, 0]], dtype=context.numpy.int64)


def kokoro_token_ids(text, parameters):
    language = required_language(parameters)
    token_map = required_token_map(parameters)
    pronunciation = phonemize(text, language)
    return token_ids(pronunciation, token_map)


def required_language(parameters):
    language = parameters.get("language")
    if not isinstance(language, str) or not language:
        raise ValueError("Die Kokoro-Transformation benötigt eine Sprache.")
    return language


def required_token_map(parameters):
    token_map = parameters.get("tokenIdMap")
    if not isinstance(token_map, dict) or not all(isinstance(value, int) for value in token_map.values()):
        raise ValueError("Die Kokoro-Transformation benötigt eine Tokenzuordnung.")
    return token_map


def phonemize(text, language):
    try:
        from phonemizer import phonemize as phonemize_text
    except ImportError as error:
        raise RuntimeError("Die Kokoro-Texttransformation benötigt phonemizer und espeak-ng.") from error
    return phonemize_text(text, language=language, backend="espeak", strip=True, preserve_punctuation=True, with_stress=True)


def token_ids(pronunciation, token_map):
    tokens = [token_map[phoneme] for phoneme in pronunciation if phoneme in token_map]
    if not tokens:
        raise ValueError("Der Text konnte nicht in Kokoro-Tokens umgewandelt werden.")
    return tokens
