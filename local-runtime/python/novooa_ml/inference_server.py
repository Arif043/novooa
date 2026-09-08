import base64
import json
import os
from collections import OrderedDict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from onnx_worker import input_arrays, runtime_dependencies, tensor_for_output
from novooa_ml.input_transforms.worker import transform_payload


class ModelNotLoadedError(Exception):
    pass


class SessionCache:
    def __init__(self, maximum_entries, session_factory):
        self._maximum_entries = maximum_entries
        self._session_factory = session_factory
        self._sessions = OrderedDict()

    def session_for(self, key, model_base64):
        session = self._sessions.pop(key, None)
        if session is not None:
            self._sessions[key] = session
            return session
        if model_base64 is None:
            raise ModelNotLoadedError()
        return self._remember(key, self._new_session(model_base64))

    def _new_session(self, model_base64):
        model_bytes = base64.b64decode(model_base64, validate=True)
        return self._session_factory(model_bytes)

    def _remember(self, key, session):
        self._sessions[key] = session
        while len(self._sessions) > self._maximum_entries:
            self._sessions.popitem(last=False)
        return session


def execute(payload, cache, numpy):
    key = required_string(payload, "modelKey")
    session = cache.session_for(key, None)
    output_names = required_list(payload, "outputNames")
    outputs = session.run(output_names, input_arrays(payload, numpy))
    return {"outputs": output_tensors(output_names, outputs, numpy)}


def load(payload, cache):
    key = required_string(payload, "modelKey")
    model_base64 = required_string(payload, "modelBase64")
    cache.session_for(key, model_base64)
    return {"status": "loaded"}


def transform(payload):
    return transform_payload(payload)


def output_tensors(output_names, outputs, numpy):
    return [
        tensor_for_output(name, value, numpy)
        for name, value in zip(output_names, outputs, strict=True)
    ]


def required_string(payload, name):
    value = payload.get(name)
    if not isinstance(value, str) or not value:
        raise ValueError(f"{name} fehlt.")
    return value


def required_list(payload, name):
    value = payload.get(name)
    if not isinstance(value, list):
        raise ValueError(f"{name} fehlt.")
    return value


def handler_for(cache, numpy):
    class InferenceHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            self._respond(200, {"status": "ok"})

        def do_POST(self):
            try:
                self._respond(200, self._response_for(self._payload()))
            except ModelNotLoadedError:
                self._respond(404, {"code": "model_not_loaded"})
            except Exception as error:
                self._respond(422, {"error": str(error)})

        def _response_for(self, payload):
            if self.path == "/v1/models":
                return load(payload, cache)
            if self.path == "/v1/inferences":
                return execute(payload, cache, numpy)
            if self.path == "/v1/input-transforms":
                return transform(payload)
            raise ValueError("Endpunkt nicht gefunden.")

        def _payload(self):
            length = int(self.headers.get("content-length", "0"))
            return json.loads(self.rfile.read(length))

        def _respond(self, status, body):
            content = json.dumps(body).encode("utf-8")
            self.send_response(status)
            self.send_header("content-type", "application/json")
            self.send_header("content-length", str(len(content)))
            self.end_headers()
            self.wfile.write(content)

        def log_message(self, format_, *args):
            return

    return InferenceHandler


def main():
    numpy, onnxruntime = runtime_dependencies()
    maximum_entries = int(os.environ.get("MODEL_SESSION_CACHE_ENTRIES", "4"))
    cache = SessionCache(maximum_entries, session_factory(onnxruntime))
    port = int(os.environ.get("PORT", "8081"))
    host = os.environ.get("HOST", "127.0.0.1")
    ThreadingHTTPServer((host, port), handler_for(cache, numpy)).serve_forever()


def session_factory(onnxruntime):
    return lambda model_bytes: onnxruntime.InferenceSession(
        model_bytes, providers=["CPUExecutionProvider"]
    )


if __name__ == "__main__":
    main()
