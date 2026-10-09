import base64
import hashlib
import json
import os
from collections import OrderedDict
from functools import partial
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import RLock

from onnx_worker import input_arrays, runtime_dependencies, transformed_output_tensors
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.transformation_capabilities import transformation_capabilities, validate_contract


class ModelNotLoadedError(Exception):
    pass


class LoadedModel:
    def __init__(self, session, resources):
        self.session = session
        self._resources = resources

    def resource_bytes(self, name):
        value = self._resources.get(name)
        if value is None:
            raise ValueError(f"Die Modellressource {name} ist nicht geladen.")
        return value


class SessionCache:
    def __init__(self, maximum_entries, session_factory):
        self._maximum_entries = maximum_entries
        self._session_factory = session_factory
        self._sessions = OrderedDict()
        self._lock = RLock()

    def session_for(self, key, model_base64, resources=None):
        return self.loaded_model_for(key, model_base64, resources).session

    def resource_bytes_for(self, key, name):
        with self._lock:
            model = self._remember_recently_used(key)
            if model is None:
                raise ModelNotLoadedError()
            return model.resource_bytes(name)

    def loaded_model_for(self, key, model_base64, resources=None):
        with self._lock:
            model = self._remember_recently_used(key)
            if model is not None:
                return model
            if model_base64 is None:
                raise ModelNotLoadedError()
            return self._remember(key, self._new_loaded_model(model_base64, resources))

    def _remember_recently_used(self, key):
        model = self._sessions.pop(key, None)
        if model is not None:
            self._sessions[key] = model
        return model

    def _new_loaded_model(self, model_base64, resources):
        model_bytes = base64.b64decode(model_base64, validate=True)
        decoded_resources = resources_from(resources)
        return LoadedModel(self._session_factory(model_bytes), decoded_resources)

    def _remember(self, key, model):
        self._sessions[key] = model
        while len(self._sessions) > self._maximum_entries:
            self._sessions.popitem(last=False)
        return model


def execute(payload, cache, numpy):
    key = required_string(payload, "modelKey")
    session = cache.session_for(key, None)
    definitions = required_list(payload, "outputs")
    outputs = session.run([definition["name"] for definition in definitions], input_arrays(payload, numpy))
    # Ausgangstransformationen lesen Modellressourcen (z. B. Label-Dateien) wie der Eingang.
    resources = partial(cache.resource_bytes_for, key)
    return {"outputs": transformed_output_tensors(payload, outputs, numpy, resources)}


def load(payload, cache):
    key = required_string(payload, "modelKey")
    model_base64 = required_string(payload, "modelBase64")
    cache.session_for(key, model_base64, payload.get("resources", []))
    return {"status": "loaded"}


def transform(payload, cache=None):
    key = payload.get("modelKey")
    if key is None:
        return transform_payload(payload)
    if cache is None:
        raise ValueError("Der Modellcache fehlt.")
    if not isinstance(key, str) or not key:
        raise ValueError("modelKey ist ungültig.")
    return transform_payload(payload, lambda name: cache.resource_bytes_for(key, name))



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
            if self.path == "/v1/transformation-capabilities":
                self._respond(200, transformation_capabilities())
                return
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
                return transform(payload, cache)
            if self.path == "/v1/contract-validations":
                return validate_contract(payload)
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


def resources_from(resources):
    if resources is None:
        return {}
    if not isinstance(resources, list):
        raise ValueError("Die Modellressourcen sind ungültig.")
    decoded = {}
    for resource in resources:
        name, content = decoded_resource(resource)
        if name in decoded:
            raise ValueError("Die Namen der Modellressourcen müssen eindeutig sein.")
        decoded[name] = content
    return decoded


def decoded_resource(resource):
    if not isinstance(resource, dict):
        raise ValueError("Eine Modellressource ist ungültig.")
    name = resource.get("name")
    content_type = resource.get("contentType")
    sha256 = resource.get("sha256")
    data_base64 = resource.get("dataBase64")
    if not isinstance(name, str) or not name:
        raise ValueError("Der Name einer Modellressource fehlt.")
    if not isinstance(content_type, str) or not content_type:
        raise ValueError("Der Content-Type einer Modellressource fehlt.")
    if not isinstance(sha256, str) or len(sha256) != 64:
        raise ValueError("Die Prüfsumme einer Modellressource ist ungültig.")
    if not isinstance(data_base64, str) or not data_base64:
        raise ValueError("Der Inhalt einer Modellressource fehlt.")
    content = base64.b64decode(data_base64, validate=True)
    if not content:
        raise ValueError("Eine Modellressource darf nicht leer sein.")
    if hashlib.sha256(content).hexdigest() != sha256.lower():
        raise ValueError("Die Prüfsumme einer Modellressource stimmt nicht mit ihrem Inhalt überein.")
    return name, content


if __name__ == "__main__":
    main()
