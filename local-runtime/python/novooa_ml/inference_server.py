import os
import re
from http.server import ThreadingHTTPServer

from novooa_bundles.bundle_file import BundleFilesMissing, bundle_file_from
from novooa_bundles.json_http import JsonRequestHandler
from novooa_ml.ml_service_config import resolver_from_environment, session_cache_bytes
from novooa_ml.model_execution import runtime_dependencies, session_factory
from novooa_ml.model_requests import ModelService
from novooa_ml.session_cache import ModelNotLoadedError, SessionCache
from novooa_ml.transformation_capabilities import transformation_capabilities, validate_contract

_UPLOAD_PATH = re.compile(r"^/v1/bundles/([a-f0-9]{64})/files/(.+)$")


def handler_for(service, store=None):
    class InferenceHandler(JsonRequestHandler):
        def do_GET(self):
            if self.path == "/v1/transformation-capabilities":
                self.respond(200, transformation_capabilities())
                return
            self.respond(200, {"status": "ok"})

        def do_POST(self):
            try:
                self.respond(200, self._response_for(self.read_json()))
            except ModelNotLoadedError:
                self.respond(404, {"code": "model_not_loaded"})
            except BundleFilesMissing as missing:
                self.respond(409, {"code": "bundle_files_missing", "missing": missing.missing})
            except Exception as error:
                self.respond(422, {"error": str(error)})

        def do_PUT(self):
            try:
                self._receive_upload()
                self.respond(201, {"status": "received"})
            except Exception as error:
                self.respond(422, {"error": str(error)})

        def _response_for(self, payload):
            routes = {
                "/v1/models": service.load, "/v1/bundles": service.prefetch,
                "/v1/inferences": service.execute, "/v1/input-transforms": service.transform,
                "/v1/contract-validations": validate_contract,
            }
            route = routes.get(self.path)
            if route is None:
                raise ValueError("Endpunkt nicht gefunden.")
            return route(payload)

        def _receive_upload(self):
            match = _UPLOAD_PATH.match(self.path)
            if match is None or store is None:
                raise ValueError("Endpunkt nicht gefunden.")
            length = int(self.headers.get("content-length", "0"))
            file = bundle_file_from({"path": match.group(2), "sha256": self.headers.get("x-sha256"), "sizeBytes": length})
            store.receive(match.group(1), file, self.rfile, length)

    return InferenceHandler


def main():
    numpy, onnxruntime = runtime_dependencies()
    resolver, store = resolver_from_environment()
    sessions = SessionCache(session_cache_bytes(), session_factory(onnxruntime))
    service = ModelService(resolver, sessions, numpy)
    port = int(os.environ.get("PORT", "8081"))
    host = os.environ.get("HOST", "127.0.0.1")
    ThreadingHTTPServer((host, port), handler_for(service, store)).serve_forever()


if __name__ == "__main__":
    main()
