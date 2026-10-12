from functools import partial

from novooa_bundles.bundle_file import bundle_files_from, validated_key
from novooa_ml.bundles.bundle_resolver import GLOBAL_SOURCE
from novooa_ml.model_execution import run_model
from novooa_ml.model_input.worker import transform_payload
from novooa_ml.session_cache import GLOBAL_SCOPE


class ModelService:
    """Die fachlichen Anfragen des ML-Dienstes, jeweils für einen Mandanten; HTTP kennt er nicht."""

    def __init__(self, resolver, sessions, numpy, queue):
        self._resolver = resolver
        self._sessions = sessions
        self._numpy = numpy
        self._queue = queue

    def load(self, tenant, payload):
        key, files = _bundle_from(payload)
        source = payload.get("source")
        bundle_path = self._resolver.resolve(tenant, key, source, files)
        scope = GLOBAL_SCOPE if source == GLOBAL_SOURCE else tenant.registration
        with self._queue.slot(tenant):
            self._sessions.load(scope, key, bundle_path, files)
        return {"status": "loaded"}

    def prefetch(self, tenant, payload):
        key, files = _bundle_from(payload)
        self._resolver.resolve(tenant, key, payload.get("source"), files)
        return {"status": "ready"}

    def execute(self, tenant, payload):
        required_list(payload, "outputs")
        with self._queue.slot(tenant):
            model = self._sessions.model_for(tenant.registration, required_string(payload, "modelKey"))
            return {"outputs": run_model(model.session, payload, self._numpy, model.resource_bytes)}

    def transform(self, tenant, payload):
        key = payload.get("modelKey")
        if key is not None and (not isinstance(key, str) or not key):
            raise ValueError("modelKey ist ungültig.")
        resources = None if key is None else partial(_resource_bytes, self._sessions, tenant.registration, key)
        with self._queue.slot(tenant):
            return transform_payload(payload) if resources is None else transform_payload(payload, resources)

    def receive(self, tenant, key, file, stream, length):
        self._resolver.receive(tenant, key, file, stream, length)

    def remove_tenant(self, tenant):
        self._sessions.unload_scope(tenant.registration)
        self._resolver.remove_tenant(tenant)


def _bundle_from(payload):
    files = bundle_files_from(payload.get("files"))
    return validated_key(required_string(payload, "modelKey"), files), files


def _resource_bytes(sessions, scope, key, name):
    return sessions.model_for(scope, key).resource_bytes(name)


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
