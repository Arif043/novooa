import base64
import sys
import unittest
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.inference_server import ModelNotLoadedError, SessionCache


class SessionCacheTest(unittest.TestCase):
    def test_reuses_a_loaded_session(self):
        factory = RecordingFactory()
        cache = SessionCache(2, factory)

        first = cache.session_for("model:1", encoded([1]))
        second = cache.session_for("model:1", None)

        self.assertIs(first, second)
        self.assertEqual(factory.models, [b"\x01"])

    def test_evicts_the_least_recently_used_session(self):
        cache = SessionCache(1, RecordingFactory())
        cache.session_for("model:1", encoded([1]))
        cache.session_for("model:2", encoded([2]))

        with self.assertRaises(ModelNotLoadedError):
            cache.session_for("model:1", None)


class RecordingFactory:
    def __init__(self):
        self.models = []

    def __call__(self, model_bytes):
        self.models.append(model_bytes)
        return object()


def encoded(values):
    return base64.b64encode(bytes(values)).decode("ascii")


if __name__ == "__main__":
    unittest.main()
