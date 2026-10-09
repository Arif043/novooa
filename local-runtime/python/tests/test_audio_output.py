import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import base64

import numpy

from ml_test_support import run
from novooa_ml.model_input.wav_decoder import decode_wav


class WaveOutputTest(unittest.TestCase):
    def test_encodes_samples_as_a_wav_file_that_decodes_back(self):
        samples = numpy.array([0.0, 0.5, -0.5, 1.0], dtype=numpy.float32)

        result = run(samples, ("audio.wav", {"sampleRate": 22050}))

        decoded, rate = decode_wav(base64.b64decode(result["dataBase64"]), result["contentType"])
        self.assertEqual((rate, result["contentType"], result["fileName"]), (22050, "audio/wav", "sprach-ausgabe.wav"))
        numpy.testing.assert_allclose(decoded[:, 0], samples, atol=1e-4)

    def test_clips_values_outside_the_valid_range(self):
        result = run(numpy.array([[2.0, -3.0]]), ("audio.wav", {"sampleRate": 8000, "fileName": "test.wav"}))

        decoded, _ = decode_wav(base64.b64decode(result["dataBase64"]), "audio/wav")
        numpy.testing.assert_allclose(decoded[:, 0], [1.0, -1.0], atol=1e-4)
        self.assertEqual(result["fileName"], "test.wav")

    def test_requires_a_positive_sample_rate(self):
        for rate in [None, 0, 44.1]:
            with self.subTest(rate=rate), self.assertRaisesRegex(ValueError, "positive sampleRate"):
                run(numpy.zeros(3), ("audio.wav", {"sampleRate": rate}))


if __name__ == "__main__":
    unittest.main()
