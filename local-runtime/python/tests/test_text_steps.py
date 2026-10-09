import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import io
from unittest.mock import patch

import numpy

from ml_test_support import context, run

PIPER = {"language": "de", "phonemeIdMap": {"^": [1], "$": [2], "h": [10], "a": 11, "l": [12], "o": [13]}}
KOKORO = {"language": "de", "tokenIdMap": {"h": 50, "a": 43, "l": 54, "o": 57}}


def fake_phonemes(text, language, model_name):
    return text.lower()


@patch("novooa_ml.transformations.text.piper_phoneme_ids.phonemize", fake_phonemes)
class PiperTest(unittest.TestCase):
    def test_frames_the_phoneme_ids_with_start_and_end_symbols(self):
        result = run("Hallo", ("text.piperPhonemes", PIPER))

        self.assertEqual((result.dtype, result.tolist()), (numpy.int64, [1, 10, 11, 12, 12, 13, 2]))

    def test_reports_the_length_for_the_second_model_input(self):
        self.assertEqual(run("Hallo", ("text.piperPhonemeLength", PIPER)).tolist(), [7])

    def test_names_an_unknown_phoneme(self):
        with self.assertRaisesRegex(ValueError, "unterstützt das Phonem 'x' nicht"):
            run("x", ("text.piperPhonemes", PIPER))

    def test_requires_language_and_phoneme_map(self):
        with self.assertRaisesRegex(ValueError, "benötigt eine Sprache"):
            run("a", ("text.piperPhonemes", {"phonemeIdMap": {}}))
        with self.assertRaisesRegex(ValueError, "Phonemzuordnung"):
            run("a", ("text.piperPhonemes", {"language": "de"}))

    def test_requires_text(self):
        with self.assertRaisesRegex(ValueError, "text.piperPhonemes erwartet Text"):
            run(42, ("text.piperPhonemes", PIPER))


@patch("novooa_ml.transformations.text.kokoro_token_ids.phonemize", fake_phonemes)
class KokoroTest(unittest.TestCase):
    def test_frames_known_tokens_and_skips_unknown_symbols(self):
        result = run("Hal lo!", ("text.kokoroTokens", KOKORO))

        self.assertEqual(result.tolist(), [[0, 50, 43, 54, 54, 57, 0]])

    def test_picks_the_style_vector_for_the_token_count_from_the_resource(self):
        voices = numpy.zeros((10, 1, 256), dtype=numpy.float32)
        voices[7] = 7
        buffer = io.BytesIO()
        numpy.savez(buffer, eva=voices)
        ctx = context(resource_reader=lambda name: buffer.getvalue() if name == "voices.npz" else b"")

        style = run("hallo", ("text.kokoroStyle", {**KOKORO, "voice": "eva", "resource": "voices.npz"}), ctx=ctx)

        self.assertEqual(style.shape, (1, 256))
        self.assertEqual(float(style[0, 0]), 7.0)

    def test_style_names_a_missing_voice_or_resource(self):
        buffer = io.BytesIO()
        numpy.savez(buffer, eva=numpy.zeros((3, 1, 256)))
        ctx = context(resource_reader=lambda name: buffer.getvalue())
        with self.assertRaisesRegex(ValueError, "Kokoro-Stimme max ist nicht vorhanden"):
            run("hallo", ("text.kokoroStyle", {**KOKORO, "voice": "max", "resource": "voices.npz"}), ctx=ctx)
        with self.assertRaisesRegex(ValueError, "benötigt eine Modellressource"):
            run("hallo", ("text.kokoroStyle", {**KOKORO, "voice": "eva"}), ctx=ctx)

    def test_fails_when_no_token_is_known(self):
        with self.assertRaisesRegex(ValueError, "nicht in Kokoro-Tokens umgewandelt"):
            run("xyz", ("text.kokoroTokens", KOKORO))


if __name__ == "__main__":
    unittest.main()
