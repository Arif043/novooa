from collections import OrderedDict
from threading import RLock

from novooa_ml.bundles.bundle_file import MODEL_FILE, RESOURCE_DIRECTORY


class ModelNotLoadedError(Exception):
    pass


class LoadedModel:
    def __init__(self, session, resources, size_bytes):
        self.session = session
        self.size_bytes = size_bytes
        self._resources = resources

    def resource_bytes(self, name):
        value = self._resources.get(name)
        if value is None:
            raise ValueError(f"Die Modellressource {name} ist nicht geladen.")
        return value


class SessionCache:
    """Geladene Modelle, begrenzt nach Bytes: Das am längsten ungenutzte fliegt zuerst, das neueste bleibt immer."""

    def __init__(self, maximum_bytes, session_factory):
        self._maximum_bytes = maximum_bytes
        self._session_factory = session_factory
        self._models = OrderedDict()
        self._lock = RLock()

    def load(self, key, bundle_path, files):
        with self._lock:
            model = self._recently_used(key)
            if model is None:
                model = self._remember(key, self._loaded(bundle_path, files))
            return model

    def model_for(self, key):
        with self._lock:
            model = self._recently_used(key)
            if model is None:
                raise ModelNotLoadedError()
            return model

    def _loaded(self, bundle_path, files):
        session = self._session_factory(str(bundle_path / MODEL_FILE))
        resources = {
            file.path.split("/", 1)[1]: (bundle_path / file.path).read_bytes()
            for file in files if file.path.startswith(f"{RESOURCE_DIRECTORY}/")
        }
        return LoadedModel(session, resources, sum(file.size_bytes for file in files))

    def _recently_used(self, key):
        model = self._models.pop(key, None)
        if model is not None:
            self._models[key] = model
        return model

    def _remember(self, key, model):
        self._models[key] = model
        total = sum(item.size_bytes for item in self._models.values())
        while total > self._maximum_bytes and len(self._models) > 1:
            _, evicted = self._models.popitem(last=False)
            total -= evicted.size_bytes
        return model
