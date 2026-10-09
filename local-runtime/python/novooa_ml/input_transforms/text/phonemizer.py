"""espeak-Phonemisierung, gemeinsam genutzt von den Piper- und Kokoro-Transformationen."""


def phonemize(text, language, model_name):
    try:
        from phonemizer import phonemize as phonemize_text
    except ImportError as error:
        raise RuntimeError(
            f"Die {model_name}-Texttransformation benötigt phonemizer und espeak-ng."
        ) from error
    return phonemize_text(
        text, language=language, backend="espeak", strip=True,
        preserve_punctuation=True, with_stress=True,
    )
