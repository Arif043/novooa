import json
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer
from pathlib import Path
from unittest.mock import patch

import numpy

from bundle_test_support import FakeGlobalStore, bundle_file, payload_for
from novooa_ml.bundles.bundle_resolver import BundleResolver
from novooa_bundles.bundle_store import BundleStore
from novooa_ml.inference_server import handler_for
from novooa_ml.model_requests import ModelService
from novooa_ml.session_cache import ModelNotLoadedError, SessionCache
from novooa_ml.transformation_capabilities import transformation_capabilities

MODEL = b"model"


class SessionCacheTest(unittest.TestCase):
    def setUp(self):
        self.bundle = Path(tempfile.mkdtemp())
        (self.bundle / "model.onnx").write_bytes(MODEL)
        (self.bundle / "resources").mkdir()
        (self.bundle / "resources" / "voice").write_bytes(b"voice")

    def test_reuses_a_loaded_session(self):
        factory = RecordingFactory()
        cache = SessionCache(100, factory)
        files = [bundle_file("model.onnx", MODEL)]

        first = cache.load("model:1", self.bundle, files)
        second = cache.load("model:1", self.bundle, files)

        self.assertIs(first, second)
        self.assertEqual(factory.paths, [str(self.bundle / "model.onnx")])

    def test_evicts_the_least_recently_used_session_beyond_the_byte_budget(self):
        cache = SessionCache(len(MODEL), RecordingFactory())
        cache.load("model:1", self.bundle, [bundle_file("model.onnx", MODEL)])
        cache.load("model:2", self.bundle, [bundle_file("model.onnx", MODEL)])

        with self.assertRaises(ModelNotLoadedError):
            cache.model_for("model:1")
        self.assertIsNotNone(cache.model_for("model:2"))

    def test_keeps_a_model_larger_than_the_budget(self):
        cache = SessionCache(1, RecordingFactory())

        cache.load("model:1", self.bundle, [bundle_file("model.onnx", MODEL)])

        self.assertIsNotNone(cache.model_for("model:1"))

    def test_keeps_resources_with_the_loaded_model(self):
        cache = SessionCache(100, RecordingFactory())

        model = cache.load("model:1", self.bundle, [bundle_file("model.onnx", MODEL), bundle_file("resources/voice", b"voice")])

        self.assertEqual(model.resource_bytes("voice"), b"voice")


class ModelServiceTest(unittest.TestCase):
    def setUp(self):
        self.files = [bundle_file("model.onnx", MODEL, "model-artifacts/a/versions/1/model.onnx")]
        resolver = BundleResolver(BundleStore(tempfile.mkdtemp()), FakeGlobalStore({"model.onnx": MODEL}))
        self.sessions = SessionCache(100, RecordingFactory())
        self.service = ModelService(resolver, self.sessions, numpy)

    def test_loads_a_global_bundle_by_reference(self):
        payload = payload_for(self.files)

        self.assertEqual(self.service.load(payload), {"status": "loaded"})
        self.assertIsNotNone(self.sessions.model_for(payload["modelKey"]))

    def test_rejects_a_key_that_does_not_match_the_files(self):
        with self.assertRaises(ValueError):
            self.service.load({**payload_for(self.files), "modelKey": "f" * 64})

    def test_delegates_input_transforms_without_a_model(self):
        with patch("novooa_ml.model_requests.transform_payload", return_value={"tensor": {"name": "image"}}) as transform:
            response = self.service.transform({"input": {"name": "image"}})

        self.assertEqual(response, {"tensor": {"name": "image"}})
        transform.assert_called_once_with({"input": {"name": "image"}})

    def test_provides_resources_of_the_loaded_model_to_transformations(self):
        bundle = Path(tempfile.mkdtemp())
        (bundle / "resources").mkdir()
        (bundle / "resources" / "voice").write_bytes(b"voice")
        self.sessions.load("model:1", bundle, [bundle_file("model.onnx", MODEL), bundle_file("resources/voice", b"voice")])
        with patch("novooa_ml.model_requests.transform_payload", return_value={}) as transform:
            self.service.transform({"modelKey": "model:1", "input": {"name": "tokens"}})

        self.assertEqual(transform.call_args.args[1]("voice"), b"voice")


class TransformationCapabilitiesTest(unittest.TestCase):
    def test_lists_the_registered_input_and_output_strategies(self):
        capabilities = transformation_capabilities()

        for name in ["image.resize", "image.resizePad", "image.resizeHeightPad", "image.padToMultiple", "tensor.channelOrder"]:
            self.assertIn(name, capabilities["inputTransformationTypes"])
        for name in ["tensor.topK", "geometry.scaleBounds", "mask.textRegions", "geometry.mergeRows"]:
            self.assertIn(name, capabilities["outputTransformationTypes"])


class InferenceEndpointTest(unittest.TestCase):
    def setUp(self):
        self.store = BundleStore(tempfile.mkdtemp())
        resolver = BundleResolver(self.store, FakeGlobalStore({}))
        service = ModelService(resolver, SessionCache(100, RecordingFactory()), numpy)
        server = ThreadingHTTPServer(("127.0.0.1", 0), handler_for(service, self.store))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        self.base = f"http://127.0.0.1:{server.server_address[1]}"

    def test_reports_missing_team_files_and_loads_after_the_upload(self):
        files = [bundle_file("model.onnx", MODEL)]
        payload = payload_for(files, source="team")

        self.assertEqual(self.post("/v1/models", payload), (409, {"code": "bundle_files_missing", "missing": ["model.onnx"]}))
        self.assertEqual(self.put(f"/v1/bundles/{payload['modelKey']}/files/model.onnx", MODEL, files[0].sha256)[0], 201)
        self.assertEqual(self.post("/v1/models", payload), (200, {"status": "loaded"}))

    def test_rejects_an_upload_with_a_wrong_checksum(self):
        status, _ = self.put(f"/v1/bundles/{'a' * 64}/files/model.onnx", MODEL, "b" * 64)

        self.assertEqual(status, 422)

    def test_validates_contracts(self):
        image_input = {"name": "bild", "source": "image", "transformations": [{"type": "image.resize", "parameters": {}}]}

        self.assertEqual(
            self.post("/v1/contract-validations", {"contract": {"inputs": [image_input], "outputs": []}}),
            (422, {"error": "Eingang bild: image.resize: Der Parameter width fehlt."}),
        )
        image_input["transformations"][0]["parameters"] = {"width": 8, "height": 8}
        self.assertEqual(self.post("/v1/contract-validations", {"contract": {"inputs": [image_input], "outputs": []}}), (200, {"status": "ok"}))

    def post(self, path, body):
        return self.send(urllib.request.Request(self.base + path, data=json.dumps(body).encode(), method="POST"))

    def put(self, path, content, sha256):
        return self.send(urllib.request.Request(self.base + path, data=content, method="PUT", headers={"x-sha256": sha256}))

    def send(self, request):
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, json.loads(response.read())
        except urllib.error.HTTPError as error:
            return error.code, json.loads(error.read())


class RecordingFactory:
    def __init__(self):
        self.paths = []

    def __call__(self, model_path):
        self.paths.append(model_path)
        return object()


if __name__ == "__main__":
    unittest.main()
