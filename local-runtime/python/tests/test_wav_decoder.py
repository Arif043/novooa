import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy

from audio_fixtures import pcm16_wav, riff_wav, sine
from novooa_ml.input_transforms.wav_decoder import decode_wav


class WavDecoderTest(unittest.TestCase):
    def test_decodes_16_bit_pcm_into_floats_with_channels(self):
        stereo = numpy.stack([sine(440, 8000, 0.1), -sine(440, 8000, 0.1)], axis=1)

        samples, sample_rate = decode_wav(pcm16_wav(stereo, 8000), "audio/wav")

        self.assertEqual(sample_rate, 8000)
        self.assertEqual(samples.shape, (800, 2))
        self.assertEqual(samples.dtype, numpy.float32)
        numpy.testing.assert_allclose(samples, stereo, atol=1e-4)

    def test_decodes_8_24_and_32_bit_pcm(self):
        cases = {
            8: (numpy.array([0, 128, 255], dtype=numpy.uint8).tobytes(), [-1.0, 0.0, 0.9921875]),
            24: (b"\x00\x00\x80" + b"\x00\x00\x00" + b"\xff\xff\x7f", [-1.0, 0.0, 0.99999988]),
            32: (numpy.array([-2**31, 0, 2**30], dtype="<i4").tobytes(), [-1.0, 0.0, 0.5]),
        }
        for bits, (data, expected) in cases.items():
            with self.subTest(bits=bits):
                samples, _ = decode_wav(riff_wav(data, 16000, 1, bits, 1), "audio/x-wav")
                numpy.testing.assert_allclose(samples[:, 0], expected, atol=1e-6)

    def test_decodes_float_and_extensible_wav(self):
        data = numpy.array([0.25, -0.5], dtype="<f4").tobytes()
        for extensible in (False, True):
            with self.subTest(extensible=extensible):
                samples, _ = decode_wav(riff_wav(data, 22050, 1, 32, 3, extensible), "audio/wave")
                numpy.testing.assert_allclose(samples[:, 0], [0.25, -0.5])

    def test_skips_unknown_chunks_before_the_data(self):
        wav = pcm16_wav(numpy.array([0.5]), 8000)
        with_list_chunk = wav[:12] + b"LIST" + (4).to_bytes(4, "little") + b"INFO" + wav[12:]

        samples, _ = decode_wav(with_list_chunk, "audio/wav")

        numpy.testing.assert_allclose(samples[:, 0], [0.5], atol=1e-4)

    def test_rejects_other_formats_and_broken_files(self):
        with self.assertRaisesRegex(ValueError, "WAV"):
            decode_wav(b"ID3...", "audio/mpeg")
        with self.assertRaisesRegex(ValueError, "WAV-Datei ist ungültig"):
            decode_wav(b"RIFF\x00\x00\x00\x00WAVE", "audio/wav")
        with self.assertRaisesRegex(ValueError, "nicht unterstützt"):
            decode_wav(riff_wav(b"\x00\x00", 8000, 1, 16, 6), "audio/wav")


if __name__ == "__main__":
    unittest.main()
