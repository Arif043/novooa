import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import math

import numpy

from ml_test_support import REGISTRY, run
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.transformations.pipeline_check import check_input_pipeline
from ml_test_support import decoded_tensor

MONDAY = "2026-10-05T14:30:15+00:00"


def features(value, **parameters):
    from novooa_ml.model_input.sources import initial_value

    return run(initial_value({"type": "datetime", "value": value}, None), ("datetime.features", parameters))


class DatetimeFeaturesTest(unittest.TestCase):
    def test_extracts_the_requested_parts_in_order(self):
        result = features(MONDAY, features=["year", "month", "day", "weekday", "hour", "minute", "second", "dayOfYear"])

        self.assertEqual(result.dtype, numpy.float32)
        self.assertEqual(result.tolist(), [2026, 10, 5, 0, 14, 30, 15, 278])

    def test_reports_seconds_since_the_epoch(self):
        self.assertEqual(features("1970-01-02T00:00:00Z", features=["epochSeconds"]).tolist(), [86400])

    def test_cyclic_encoding_makes_midnight_and_the_end_of_day_neighbours(self):
        midnight = features("2026-10-05T00:00:00Z", features=["hour"], cyclic=True)
        late = features("2026-10-05T23:00:00Z", features=["hour"], cyclic=True)
        noon = features("2026-10-05T12:00:00Z", features=["hour"], cyclic=True)

        numpy.testing.assert_allclose(midnight, [0.0, 1.0], atol=1e-6)
        self.assertLess(numpy.linalg.norm(midnight - late), numpy.linalg.norm(midnight - noon))
        numpy.testing.assert_allclose(late, [math.sin(2 * math.pi * 23 / 24), math.cos(2 * math.pi * 23 / 24)], atol=1e-6)

    def test_cyclic_encoding_leaves_linear_parts_as_they_are(self):
        result = features(MONDAY, features=["year", "weekday"], cyclic=True)

        self.assertEqual(result.shape, (3,))
        self.assertEqual(float(result[0]), 2026.0)

    def test_converts_into_the_requested_time_zone(self):
        result = features("2026-10-05T23:30:00Z", features=["day", "hour"], timeZone="Europe/Berlin")

        self.assertEqual(result.tolist(), [6, 1])

    def test_treats_times_without_offset_as_utc(self):
        self.assertEqual(features("2026-10-05T10:00:00", features=["hour"], timeZone="Europe/Berlin").tolist(), [12])

    def test_rejects_invalid_input_and_parameters(self):
        for value, parameters, message in [
            ("gestern", {"features": ["hour"]}, "kein gültiges ISO-8601-Datum"),
            (MONDAY, {"features": []}, "nicht leere Liste features"),
            (MONDAY, {"features": ["quarter"]}, "unbekannte Merkmal quarter"),
            (MONDAY, {"features": ["hour"], "timeZone": "Mars/Base"}, "Zeitzone Mars/Base"),
            (MONDAY, {"features": ["hour"], "cyclic": "ja"}, "cyclic"),
        ]:
            with self.subTest(parameters=parameters), self.assertRaisesRegex(ValueError, message):
                features(value, **parameters)

    def test_runs_end_to_end_as_model_input(self):
        payload = {
            "input": {
                "name": "zeitpunkt", "dataType": "float32", "shape": ["dynamic", 2],
                "transformations": [{"type": "datetime.features", "parameters": {"features": ["month", "hour"]}}],
            },
            "source": {"type": "datetime", "value": MONDAY},
        }

        self.assertEqual(decoded_tensor(transform_payload(payload)["tensor"]).tolist(), [[10, 14]])

    def test_datetime_sources_must_be_turned_into_features(self):
        check_input_pipeline("zeitpunkt", "datetime", [{"type": "datetime.features", "parameters": {}}], REGISTRY)
        with self.assertRaisesRegex(ValueError, "enden aber bei datetime"):
            check_input_pipeline("zeitpunkt", "datetime", [], REGISTRY)


if __name__ == "__main__":
    unittest.main()
