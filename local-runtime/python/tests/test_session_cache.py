import tempfile
import unittest
from pathlib import Path

from bundle_test_support import RecordingFactory, bundle_file
from novooa_ml.session_cache import GLOBAL_SCOPE, ModelNotLoadedError, ModelTooLargeError, SessionCache

MODEL = b"model"
FILES = [bundle_file("model.onnx", MODEL)]


class SessionCacheTest(unittest.TestCase):
    def setUp(self):
        self.bundle = Path(tempfile.mkdtemp())
        (self.bundle / "model.onnx").write_bytes(MODEL)
        (self.bundle / "resources").mkdir()
        (self.bundle / "resources" / "voice").write_bytes(b"voice")

    def test_reuses_a_loaded_session(self):
        factory = RecordingFactory()
        cache = SessionCache(100, factory)

        first = cache.load(GLOBAL_SCOPE, "model:1", self.bundle, FILES)
        second = cache.load(GLOBAL_SCOPE, "model:1", self.bundle, FILES)

        self.assertIs(first, second)
        self.assertEqual(factory.paths, [str(self.bundle / "model.onnx")])

    def test_global_models_are_shared_and_team_models_are_not(self):
        cache = SessionCache(100, RecordingFactory())
        cache.load(GLOBAL_SCOPE, "catalog", self.bundle, FILES)
        cache.load("tenant-a", "team", self.bundle, FILES)

        self.assertIsNotNone(cache.model_for("tenant-b", "catalog"))
        with self.assertRaises(ModelNotLoadedError):
            cache.model_for("tenant-b", "team")

    def test_makes_room_by_evicting_the_least_recently_used_model(self):
        cache = SessionCache(len(MODEL), RecordingFactory())
        cache.load(GLOBAL_SCOPE, "model:1", self.bundle, FILES)
        cache.load(GLOBAL_SCOPE, "model:2", self.bundle, FILES)

        with self.assertRaises(ModelNotLoadedError):
            cache.model_for(GLOBAL_SCOPE, "model:1")
        self.assertIsNotNone(cache.model_for(GLOBAL_SCOPE, "model:2"))

    def test_rejects_a_model_that_never_fits(self):
        cache = SessionCache(len(MODEL) - 1, RecordingFactory())

        with self.assertRaises(ModelTooLargeError):
            cache.load(GLOBAL_SCOPE, "model:1", self.bundle, FILES)

    def test_a_tenant_over_its_share_evicts_its_own_models_first(self):
        cache = SessionCache(len(MODEL) * 3, RecordingFactory(), tenant_maximum_bytes=len(MODEL))
        cache.load("tenant-b", "b", self.bundle, FILES)
        cache.load("tenant-a", "a1", self.bundle, FILES)

        cache.load("tenant-a", "a2", self.bundle, FILES)

        self.assertIsNotNone(cache.model_for("tenant-b", "b"))
        with self.assertRaises(ModelNotLoadedError):
            cache.model_for("tenant-a", "a1")

    def test_keeps_resources_with_the_loaded_model(self):
        cache = SessionCache(100, RecordingFactory())

        model = cache.load(GLOBAL_SCOPE, "model:1", self.bundle, FILES + [bundle_file("resources/voice", b"voice")])

        self.assertEqual(model.resource_bytes("voice"), b"voice")


if __name__ == "__main__":
    unittest.main()
