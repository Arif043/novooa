import base64
import hashlib
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from novooa_ml.inference_server import ModelNotLoadedError, SessionCache, transformation_capabilities, transform


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

    def test_keeps_resources_with_the_cached_model(self):
        cache = SessionCache(1, RecordingFactory())

        cache.session_for("model:1", encoded([1]), [resource("voice", [2, 3])])

        self.assertEqual(cache.resource_bytes_for("model:1", "voice"), b"\x02\x03")

    def test_does_not_cache_an_invalid_resource_bundle(self):
        cache = SessionCache(1, RecordingFactory())

        with self.assertRaises(ValueError):
            cache.session_for("model:1", encoded([1]), [{"name": "voice"}])

        with self.assertRaises(ModelNotLoadedError):
            cache.session_for("model:1", None)

    def test_delegates_image_transforms_to_the_worker(self):
        with patch(
            "novooa_ml.inference_server.transform_payload",
            return_value={"tensor": {"name": "image"}},
        ) as transform_payload:
            response = transform({"input": {"name": "image"}})

        self.assertEqual(response, {"tensor": {"name": "image"}})
        transform_payload.assert_called_once_with({"input": {"name": "image"}})

    def test_provides_cached_resources_to_model_aware_transformations(self):
        cache = ResourceCache()
        with patch(
            "novooa_ml.inference_server.transform_payload",
            return_value={"tensor": {"name": "tokens"}},
        ) as transform_payload:
            response = transform({"modelKey": "model:1", "input": {"name": "tokens"}}, cache)

        reader = transform_payload.call_args.args[1]
        self.assertEqual(reader("voice"), b"voice")
        self.assertEqual(response, {"tensor": {"name": "tokens"}})
        self.assertEqual(cache.requests, [("model:1", "voice")])


class TransformationCapabilitiesTest(unittest.TestCase):
    def test_lists_the_registered_input_and_output_strategies(self):
        capabilities = transformation_capabilities()

        self.assertIn("image.resize", capabilities["inputTransformationTypes"])
        self.assertIn("image.resizePad", capabilities["inputTransformationTypes"])
        self.assertIn("image.resizeHeightPad", capabilities["inputTransformationTypes"])
        self.assertIn("image.padToMultiple", capabilities["inputTransformationTypes"])
        self.assertIn("tensor.channelOrder", capabilities["inputTransformationTypes"])
        self.assertIn("tensor.topK", capabilities["outputTransformationTypes"])
        self.assertIn("geometry.scaleBounds", capabilities["outputTransformationTypes"])
        self.assertIn("mask.textRegions", capabilities["outputTransformationTypes"])
        self.assertIn("geometry.mergeRows", capabilities["outputTransformationTypes"])


class RecordingFactory:
    def __init__(self):
        self.models = []

    def __call__(self, model_bytes):
        self.models.append(model_bytes)
        return object()


class ResourceCache:
    def __init__(self):
        self.requests = []

    def resource_bytes_for(self, key, name):
        self.requests.append((key, name))
        return b"voice"


def encoded(values):
    return base64.b64encode(bytes(values)).decode("ascii")


def resource(name, values):
    return {
        "name": name,
        "contentType": "application/octet-stream",
        "sha256": hashlib.sha256(bytes(values)).hexdigest(),
        "dataBase64": encoded(values),
    }


if __name__ == "__main__":
    unittest.main()
