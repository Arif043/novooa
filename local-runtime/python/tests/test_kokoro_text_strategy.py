import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.transformations.text.kokoro_token_ids import token_ids


class KokoroTextStrategyTest(unittest.TestCase):
    def test_converts_supported_phonemes_to_token_ids(self):
        tokens = token_ids("a b", {"a": 10, " ": 11, "b": 12})

        self.assertEqual(tokens, [10, 11, 12])

    def test_rejects_text_without_supported_phonemes(self):
        with self.assertRaisesRegex(ValueError, "Kokoro-Tokens"):
            token_ids("x", {"a": 10})


if __name__ == "__main__":
    unittest.main()
