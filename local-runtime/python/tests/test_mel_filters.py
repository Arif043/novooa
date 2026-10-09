import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import numpy

import ml_test_support  # noqa: F401  (setzt den Paketpfad)
from novooa_ml.transformations.audio.mel_filters import hz_to_mel, mel_filter_bank, mel_to_hz


class MelScaleTest(unittest.TestCase):
    def test_slaney_scale_is_linear_below_1000_hz(self):
        self.assertAlmostEqual(float(hz_to_mel(numpy, 500, "slaney")), 7.5)
        self.assertAlmostEqual(float(hz_to_mel(numpy, 1000, "slaney")), 15.0)

    def test_htk_scale_matches_its_definition(self):
        self.assertAlmostEqual(float(hz_to_mel(numpy, 700, "htk")), 2595 * numpy.log10(2), places=4)

    def test_conversion_round_trips_for_both_scales(self):
        frequencies = numpy.array([0, 300, 999, 1000, 4000, 8000])
        for scale in ("slaney", "htk"):
            with self.subTest(scale=scale):
                numpy.testing.assert_allclose(mel_to_hz(numpy, hz_to_mel(numpy, frequencies, scale), scale), frequencies, atol=1e-6)


class MelFilterBankTest(unittest.TestCase):
    def bank(self, scale="slaney", normalization="slaney"):
        return mel_filter_bank(numpy, 16000, 400, 40, 0, 8000, scale, normalization)

    def test_has_one_row_per_mel_bin_and_one_column_per_frequency(self):
        self.assertEqual(self.bank().shape, (40, 201))

    def test_filters_are_non_negative_triangles_with_a_single_peak(self):
        for row in self.bank(normalization="none"):
            nonzero = numpy.flatnonzero(row)
            peak = int(numpy.argmax(row))
            self.assertTrue(numpy.all(row >= 0))
            self.assertTrue(numpy.all(numpy.diff(row[nonzero[0]:peak + 1]) >= 0))
            self.assertTrue(numpy.all(numpy.diff(row[peak:nonzero[-1] + 1]) <= 0))
            self.assertLessEqual(float(row.max()), 1.0)

    def test_filter_centers_rise_with_the_mel_bin(self):
        centers = numpy.argmax(self.bank(), axis=1)

        self.assertTrue(numpy.all(numpy.diff(centers) >= 0))
        self.assertGreater(int(centers[-1]), int(centers[0]))

    def test_slaney_normalization_gives_wider_filters_lower_peaks(self):
        peaks = self.bank().max(axis=1)

        self.assertGreater(float(peaks[0]), float(peaks[-1]))


if __name__ == "__main__":
    unittest.main()
