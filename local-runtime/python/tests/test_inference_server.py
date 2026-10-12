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

from bundle_test_support import TENANT_A, FakeGlobalStore, RecordingFactory, UnlimitedQueue, bundle_file, payload_for
from novooa_bundles.bundle_store import BundleStore
from novooa_ml.bundles.bundle_resolver import BundleResolver
from novooa_ml.bundles.team_stores import TeamStores
from novooa_ml.inference_server import handler_for
from novooa_ml.model_requests import ModelService
from novooa_ml.session_cache import ModelNotLoadedError, SessionCache
from novooa_ml.tenants.tenancy import RegisteredTenants
from novooa_ml.tenants.tenant_registry import TenantRegistry
from novooa_ml.transformation_capabilities import transformation_capabilities

MODEL = b"model"


class ModelServiceTest(unittest.TestCase):
    def setUp(self):
        self.files = [bundle_file("model.onnx", MODEL, "model-artifacts/a/versions/1/model.onnx")]
        root = Path(tempfile.mkdtemp())
        resolver = BundleResolver(BundleStore(root / "global"), FakeGlobalStore({"model.onnx": MODEL}), TeamStores(root / "teams"))
        self.sessions = SessionCache(100, RecordingFactory())
        self.service = ModelService(resolver, self.sessions, numpy, UnlimitedQueue())

    def test_loads_a_global_bundle_once_for_every_tenant(self):
        payload = payload_for(self.files)

        self.assertEqual(self.service.load(TENANT_A, payload), {"status": "loaded"})
        self.assertIsNotNone(self.sessions.model_for("another-registration", payload["modelKey"]))

    def test_rejects_a_key_that_does_not_match_the_files(self):
        with self.assertRaises(ValueError):
            self.service.load(TENANT_A, {**payload_for(self.files), "modelKey": "f" * 64})

    def test_delegates_input_transforms_without_a_model(self):
        with patch("novooa_ml.model_requests.transform_payload", return_value={"tensor": {"name": "image"}}) as transform:
            response = self.service.transform(TENANT_A, {"input": {"name": "image"}})

        self.assertEqual(response, {"tensor": {"name": "image"}})
        transform.assert_called_once_with({"input": {"name": "image"}})

    def test_provides_resources_of_the_tenants_model_to_transformations(self):
        files = [bundle_file("model.onnx", MODEL), bundle_file("resources/voice", b"voice")]
        self.sessions.load(TENANT_A.registration, "model:1", resource_bundle(), files)
        with patch("novooa_ml.model_requests.transform_payload", return_value={}) as transform:
            self.service.transform(TENANT_A, {"modelKey": "model:1", "input": {"name": "tokens"}})

        self.assertEqual(transform.call_args.args[1]("voice"), b"voice")

    def test_removing_a_tenant_unloads_its_models(self):
        self.sessions.load(TENANT_A.registration, "model:1", resource_bundle(), [bundle_file("model.onnx", MODEL)])

        self.service.remove_tenant(TENANT_A)

        with self.assertRaises(ModelNotLoadedError):
            self.sessions.model_for(TENANT_A.registration, "model:1")


class TransformationCapabilitiesTest(unittest.TestCase):
    def test_lists_the_registered_input_and_output_strategies(self):
        capabilities = transformation_capabilities()

        for name in ["image.resize", "image.resizePad", "image.resizeHeightPad", "image.padToMultiple", "tensor.channelOrder"]:
            self.assertIn(name, capabilities["inputTransformationTypes"])
        for name in ["tensor.topK", "geometry.scaleBounds", "mask.textRegions", "geometry.mergeRows"]:
            self.assertIn(name, capabilities["outputTransformationTypes"])


class InferenceEndpointTest(unittest.TestCase):
    def setUp(self):
        root = Path(tempfile.mkdtemp())
        resolver = BundleResolver(BundleStore(root / "global"), FakeGlobalStore({}), TeamStores(root / "teams"))
        service = ModelService(resolver, SessionCache(100, RecordingFactory()), numpy, UnlimitedQueue())
        tenancy = RegisteredTenants(TenantRegistry(root / "tenants.sqlite3"))
        server = ThreadingHTTPServer(("127.0.0.1", 0), handler_for(service, tenancy))
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        self.base = f"http://127.0.0.1:{server.server_address[1]}"

    def test_registers_once_per_tenant_id(self):
        status, body = self.post("/v1/tenants", {"tenantId": "workspace-a"})

        self.assertEqual(status, 201)
        self.assertTrue(body["token"].startswith("nml_"))
        self.assertEqual(self.post("/v1/tenants", {"tenantId": "workspace-a"})[1]["code"], "tenant_exists")

    def test_rejects_requests_without_a_valid_token(self):
        self.assertEqual(self.post("/v1/contract-validations", {"contract": {}})[0], 401)
        self.assertEqual(self.post("/v1/contract-validations", {"contract": {}}, token="nml_wrong")[0], 401)

    def test_reports_missing_team_files_and_loads_after_the_upload(self):
        token = self.register("workspace-a")
        files = [bundle_file("model.onnx", MODEL)]
        payload = payload_for(files, source="team")

        self.assertEqual(self.post("/v1/models", payload, token), (409, {"code": "bundle_files_missing", "missing": ["model.onnx"]}))
        self.assertEqual(self.put(f"/v1/bundles/{payload['modelKey']}/files/model.onnx", MODEL, files[0].sha256, token)[0], 201)
        self.assertEqual(self.post("/v1/models", payload, token), (200, {"status": "loaded"}))

    def test_a_team_upload_of_one_tenant_does_not_help_another(self):
        first, second = self.register("workspace-a"), self.register("workspace-b")
        files = [bundle_file("model.onnx", MODEL)]
        payload = payload_for(files, source="team")
        self.put(f"/v1/bundles/{payload['modelKey']}/files/model.onnx", MODEL, files[0].sha256, first)

        self.assertEqual(self.post("/v1/models", payload, first)[0], 200)
        self.assertEqual(self.post("/v1/models", payload, second)[0], 409)

    def test_unregistering_invalidates_the_token_and_frees_the_id(self):
        token = self.register("workspace-a")

        self.assertEqual(self.send(self.request("/v1/tenants/self", None, "DELETE", token))[0], 200)
        self.assertEqual(self.post("/v1/contract-validations", {"contract": {}}, token)[0], 401)
        self.assertEqual(self.post("/v1/tenants", {"tenantId": "workspace-a"})[0], 201)

    def test_rejects_an_upload_with_a_wrong_checksum(self):
        token = self.register("workspace-a")

        self.assertEqual(self.put(f"/v1/bundles/{'a' * 64}/files/model.onnx", MODEL, "b" * 64, token)[0], 422)

    def test_validates_contracts(self):
        token = self.register("workspace-a")
        image_input = {"name": "bild", "source": "image", "transformations": [{"type": "image.resize", "parameters": {}}]}
        contract = {"contract": {"inputs": [image_input], "outputs": []}}

        self.assertEqual(self.post("/v1/contract-validations", contract, token), (422, {"error": "Eingang bild: image.resize: Der Parameter width fehlt."}))
        image_input["transformations"][0]["parameters"] = {"width": 8, "height": 8}
        self.assertEqual(self.post("/v1/contract-validations", contract, token), (200, {"status": "ok"}))

    def register(self, tenant_id):
        return self.post("/v1/tenants", {"tenantId": tenant_id})[1]["token"]

    def post(self, path, body, token=None):
        return self.send(self.request(path, json.dumps(body).encode(), "POST", token))

    def put(self, path, content, sha256, token):
        return self.send(self.request(path, content, "PUT", token, {"x-sha256": sha256}))

    def request(self, path, data, method, token, headers=None):
        headers = {**(headers or {}), **({"authorization": f"Bearer {token}"} if token else {})}
        return urllib.request.Request(self.base + path, data=data, method=method, headers=headers)

    def send(self, request):
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, json.loads(response.read())
        except urllib.error.HTTPError as error:
            return error.code, json.loads(error.read())


def resource_bundle():
    bundle = Path(tempfile.mkdtemp())
    (bundle / "resources").mkdir()
    (bundle / "resources" / "voice").write_bytes(b"voice")
    return bundle


if __name__ == "__main__":
    unittest.main()
