import os
import re
from http.server import ThreadingHTTPServer

from novooa_bundles.bundle_file import bundle_file_from
from novooa_bundles.json_http import JsonRequestHandler
from novooa_ml.http_errors import EndpointNotFound, error_response
from novooa_ml.ml_service_config import service_from_environment
from novooa_ml.model_execution import runtime_dependencies
from novooa_ml.transformation_capabilities import transformation_capabilities, validate_contract

_UPLOAD_PATH = re.compile(r"^/v1/bundles/([a-f0-9]{64})/files/(.+)$")
_TENANT_ROUTES = {
    "/v1/models": lambda service, tenant, payload: service.load(tenant, payload),
    "/v1/bundles": lambda service, tenant, payload: service.prefetch(tenant, payload),
    "/v1/inferences": lambda service, tenant, payload: service.execute(tenant, payload),
    "/v1/input-transforms": lambda service, tenant, payload: service.transform(tenant, payload),
    "/v1/contract-validations": lambda service, tenant, payload: validate_contract(payload),
}


def handler_for(service, tenancy):
    class InferenceHandler(JsonRequestHandler):
        def do_GET(self):
            if self.path == "/v1/transformation-capabilities":
                self.respond(200, transformation_capabilities())
                return
            self.respond(200, {"status": "ok"})

        def do_POST(self):
            self._guarded(self._post)

        def do_PUT(self):
            self._guarded(self._put)

        def do_DELETE(self):
            self._guarded(self._delete)

        def _post(self):
            if self.path == "/v1/tenants":
                return 201, tenancy.register(self.read_json())
            tenant = self._tenant()
            route = _TENANT_ROUTES.get(self.path)
            if route is None:
                raise EndpointNotFound()
            return 200, route(service, tenant, self.read_json())

        def _put(self):
            match = _UPLOAD_PATH.match(self.path)
            if match is None:
                raise EndpointNotFound()
            tenant = self._tenant()
            length = int(self.headers.get("content-length", "0"))
            file = bundle_file_from({"path": match.group(2), "sha256": self.headers.get("x-sha256"), "sizeBytes": length})
            service.receive(tenant, match.group(1), file, self.rfile, length)
            return 201, {"status": "received"}

        def _delete(self):
            if self.path != "/v1/tenants/self":
                raise EndpointNotFound()
            tenant = self._tenant()
            # Erst das Token entwerten, dann aufräumen: Danach kommt keine Anfrage dieses Mandanten mehr durch.
            tenancy.unregister(tenant)
            service.remove_tenant(tenant)
            return 200, {"status": "removed"}

        def _tenant(self):
            return tenancy.tenant_for(self.headers.get("authorization"))

        def _guarded(self, action):
            try:
                status, body = action()
                self.respond(status, body)
            except Exception as error:
                status, body, headers = error_response(error)
                self.respond(status, body, headers)

    return InferenceHandler


def main():
    numpy, onnxruntime = runtime_dependencies()
    service, tenancy = service_from_environment(numpy, onnxruntime)
    port = int(os.environ.get("PORT", "8081"))
    host = os.environ.get("HOST", "127.0.0.1")
    ThreadingHTTPServer((host, port), handler_for(service, tenancy)).serve_forever()


if __name__ == "__main__":
    main()
