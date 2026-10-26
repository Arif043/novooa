import base64
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy

from audio_fixtures import audio_payload, dominant_frequency, pcm16_wav, sine
from novooa_ml.model_input.worker import transform_payload


def tensor_of(wav, transformations, shape=None):
    payload = audio_payload(wav, [{"type": kind, "parameters": parameters} for kind, parameters in transformations], shape or ["dynamic"])
    result = transform_payload(payload)["tensor"]
    values = numpy.frombuffer(base64.b64decode(result["dataBase64"]), dtype=numpy.float32)
    return values.reshape(result["shape"])


class AudioSourceTest(unittest.TestCase):
    def test_mono_audio_becomes_a_one_dimensional_tensor(self):
        tensor = tensor_of(pcm16_wav(sine(440, 8000, 0.25), 8000), [], ["dynamic"])

        self.assertEqual(tensor.shape, (2000,))

    def test_multichannel_audio_becomes_channels_by_samples(self):
        stereo = numpy.stack([sine(440, 8000, 0.1), numpy.zeros(800)], axis=1)

        tensor = tensor_of(pcm16_wav(stereo, 8000), [], [2, "dynamic"])

        self.assertEqual(tensor.shape, (2, 800))
        self.assertAlmostEqual(float(numpy.abs(tensor[1]).max()), 0.0)

    def test_audio_transformations_must_come_before_tensor_operations(self):
        with self.assertRaisesRegex(ValueError, "audio.mono"):
            tensor_of(pcm16_wav(sine(440, 8000, 0.1), 8000), [("tensor.scale", {"factor": 2}), ("audio.mono", {})])


class MonoTest(unittest.TestCase):
    def test_averages_all_channels(self):
        stereo = numpy.stack([numpy.full(4, 0.5), numpy.full(4, -0.25)], axis=1)

        tensor = tensor_of(pcm16_wav(stereo, 8000), [("audio.mono", {})])

        numpy.testing.assert_allclose(tensor, [0.125] * 4, atol=1e-4)


class ResampleTest(unittest.TestCase):
    def test_changes_the_rate_and_keeps_the_pitch(self):
        tensor = tensor_of(pcm16_wav(sine(440, 48000, 0.5), 48000), [("audio.resample", {"sampleRate": 16000})])

        self.assertEqual(tensor.shape, (8000,))
        self.assertAlmostEqual(dominant_frequency(tensor, 16000), 440, delta=3)

    def test_keeps_audio_already_at_the_target_rate(self):
        original = sine(440, 16000, 0.1)

        tensor = tensor_of(pcm16_wav(original, 16000), [("audio.resample", {"sampleRate": 16000})])

        numpy.testing.assert_allclose(tensor, original, atol=1e-4)

    def test_rejects_an_invalid_rate(self):
        with self.assertRaisesRegex(ValueError, "sampleRate"):
            tensor_of(pcm16_wav(sine(440, 8000, 0.1), 8000), [("audio.resample", {"sampleRate": 0})])


class NormalizeTest(unittest.TestCase):
    def test_scales_to_the_peak(self):
        tensor = tensor_of(pcm16_wav(sine(440, 8000, 0.1, amplitude=0.25), 8000), [("audio.normalize", {"mode": "peak"})])

        self.assertAlmostEqual(float(numpy.abs(tensor).max()), 1.0, places=3)

    def test_scales_to_a_target_rms(self):
        tensor = tensor_of(pcm16_wav(sine(440, 8000, 0.5, amplitude=0.1), 8000), [("audio.normalize", {"mode": "rms", "target": 0.2})])

        self.assertAlmostEqual(float(numpy.sqrt(numpy.mean(tensor ** 2))), 0.2, places=3)

    def test_leaves_silence_unchanged(self):
        tensor = tensor_of(pcm16_wav(numpy.zeros(10), 8000), [("audio.normalize", {})])

        numpy.testing.assert_allclose(tensor, numpy.zeros(10))


class FitDurationTest(unittest.TestCase):
    def test_pads_with_silence_or_trims_to_the_duration(self):
        short = tensor_of(pcm16_wav(numpy.full(4000, 0.5), 8000), [("audio.fitDuration", {"seconds": 1})])
        long = tensor_of(pcm16_wav(numpy.linspace(-1, 1, 16000), 8000), [("audio.fitDuration", {"seconds": 1, "keep": "end"})])

        self.assertEqual(short.shape, (8000,))
        self.assertAlmostEqual(float(short[-1]), 0.0)
        self.assertEqual(long.shape, (8000,))
        self.assertAlmostEqual(float(long[-1]), 1.0, places=3)


class MelSpectrogramTest(unittest.TestCase):
    def test_produces_mel_bins_by_frames(self):
        tensor = tensor_of(
            pcm16_wav(sine(1000, 16000, 1.0), 16000),
            [("audio.melSpectrogram", {"frameLength": 400, "hopLength": 160, "melBins": 80})],
            [80, "dynamic"],
        )

        self.assertEqual(tensor.shape, (80, 101))
        self.assertTrue(numpy.all(tensor >= 0))

    def test_a_higher_tone_lands_in_a_higher_mel_bin(self):
        def peak_bin(frequency):
            tensor = tensor_of(pcm16_wav(sine(frequency, 16000, 0.5), 16000), [("audio.melSpectrogram", {"melBins": 40})], [40, "dynamic"])
            return int(numpy.argmax(tensor.mean(axis=1)))

        self.assertLess(peak_bin(300), peak_bin(1000))
        self.assertLess(peak_bin(1000), peak_bin(4000))

    def test_log_scales_limit_the_dynamic_range(self):
        tensor = tensor_of(
            pcm16_wav(sine(1000, 16000, 0.5), 16000),
            [("audio.melSpectrogram", {"melBins": 40, "scale": "log10", "dynamicRange": 8})],
            [40, "dynamic"],
        )

        self.assertAlmostEqual(float(tensor.max() - tensor.min()), 8.0, places=4)

    def test_decibel_scale_peaks_relative_to_the_maximum(self):
        tensor = tensor_of(pcm16_wav(sine(1000, 16000, 0.5), 16000), [("audio.melSpectrogram", {"melBins": 40, "scale": "db"})], [40, "dynamic"])

        self.assertAlmostEqual(float(tensor.max()), 0.0, places=4)
        self.assertLess(float(tensor.min()), -20)

    def test_supports_the_htk_mel_scale_without_normalization(self):
        tensor = tensor_of(
            pcm16_wav(sine(1000, 16000, 0.25), 16000),
            [("audio.melSpectrogram", {"melBins": 20, "melScale": "htk", "filterNormalization": "none", "center": False})],
            [20, "dynamic"],
        )

        self.assertEqual(tensor.shape, (20, 1 + (4000 - 400) // 160))

    def test_rejects_invalid_parameters(self):
        wav = pcm16_wav(sine(1000, 16000, 0.1), 16000)
        for parameters, message in [
            ({"scale": "ln"}, "scale"),
            ({"melScale": "bark"}, "melScale"),
            ({"maxFrequency": 9000}, "maxFrequency"),
            ({"frameLength": 0}, "frameLength"),
        ]:
            with self.subTest(parameters=parameters), self.assertRaisesRegex(ValueError, message):
                tensor_of(wav, [("audio.melSpectrogram", parameters)], [80, "dynamic"])



class StandardizeTest(unittest.TestCase):
    """Referenz: Wav2Vec2FeatureExtractor.zero_mean_unit_var_norm — (x − mean) / sqrt(var + 1e-7)."""

    def test_matches_the_wav2vec2_feature_extractor(self):
        samples = numpy.linspace(-0.5, 0.9, 400) + 0.1
        tensor = tensor_of(pcm16_wav(samples, 8000), [("audio.normalize", {"mode": "zscore"})])
        decoded = numpy.round(samples * 32767) / 32767

        expected = (decoded - decoded.mean()) / numpy.sqrt(decoded.var() + 1e-7)
        numpy.testing.assert_allclose(tensor, expected, atol=1e-4)
        self.assertAlmostEqual(float(tensor.mean()), 0.0, places=5)

    def test_keeps_silence_finite(self):
        tensor = tensor_of(pcm16_wav(numpy.zeros(10), 8000), [("audio.normalize", {"mode": "zscore"})])

        numpy.testing.assert_allclose(tensor, numpy.zeros(10))


if __name__ == "__main__":
    unittest.main()
