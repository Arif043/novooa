from functools import partial

from novooa_bundles.bundle_file import bundle_files_from, validated_key
from novooa_ml.model_execution import run_model
from novooa_ml.model_input.worker import transform_payload


class ModelService:
    """Die fachlichen Anfragen des ML-Dienstes; HTTP kennt er nicht."""

    def __init__(self, resolver, sessions, numpy):
        self._resolver = resolver
        self._sessions = sessions
        self._numpy = numpy

    def load(self, payload):
        key, files = _bundle_from(payload)
        bundle_path = self._resolver.resolve(key, payload.get("source"), files)
        self._sessions.load(key, bundle_path, files)
        return {"status": "loaded"}

    def prefetch(self, payload):
        key, files = _bundle_from(payload)
        self._resolver.resolve(key, payload.get("source"), files)
        return {"status": "ready"}

    def execute(self, payload):
        model = self._sessions.model_for(required_string(payload, "modelKey"))
        required_list(payload, "outputs")
        outputs = run_model(model.session, payload, self._numpy, model.resource_bytes)
        return {"outputs": outputs}

    def transform(self, payload):
        key = payload.get("modelKey")
        if key is None:
            return transform_payload(payload)
        if not isinstance(key, str) or not key:
            raise ValueError("modelKey ist ungültig.")
        return transform_payload(payload, partial(_resource_bytes, self._sessions, key))


def _bundle_from(payload):
    files = bundle_files_from(payload.get("files"))
    return validated_key(required_string(payload, "modelKey"), files), files


def _resource_bytes(sessions, key, name):
    return sessions.model_for(key).resource_bytes(name)


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
