from collections import OrderedDict
from threading import Lock, RLock

from novooa_bundles.bundle_file import MODEL_FILE, RESOURCE_DIRECTORY

GLOBAL_SCOPE = "global"


class ModelNotLoadedError(Exception):
    pass


class ModelTooLargeError(Exception):
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
    """
    Geladene Modelle, begrenzt nach Bytes. Globale Modelle teilen sich alle Mandanten (Bereich `global`),
    Teammodelle liegen im Bereich ihrer Registrierung. Vor dem Laden wird Platz geschaffen, damit der Speicher
    nicht kurzzeitig über das Budget wächst; ein Modell, das nie hineinpasst, wird abgelehnt.
    """

    def __init__(self, maximum_bytes, session_factory, tenant_maximum_bytes=None):
        self._maximum_bytes = maximum_bytes
        self._tenant_maximum_bytes = tenant_maximum_bytes
        self._session_factory = session_factory
        self._models = OrderedDict()
        self._lock = RLock()
        self._loading = {}

    def load(self, scope, key, bundle_path, files):
        entry = (scope, key)
        size = sum(file.size_bytes for file in files)
        with self._loading_lock(entry):
            with self._lock:
                model = self._recently_used(entry)
                if model is not None:
                    return model
                self._make_room(scope, size)
            model = self._loaded(bundle_path, files, size)
            with self._lock:
                self._models[entry] = model
                return model

    def model_for(self, scope, key):
        """Sucht zuerst im Bereich des Mandanten, dann unter den globalen Modellen."""
        with self._lock:
            model = self._recently_used((scope, key)) or self._recently_used((GLOBAL_SCOPE, key))
            if model is None:
                raise ModelNotLoadedError()
            return model

    def unload_scope(self, scope):
        with self._lock:
            for entry in [entry for entry in self._models if entry[0] == scope]:
                del self._models[entry]

    def _make_room(self, scope, size):
        limit = self._limit_for(scope)
        if size > limit:
            raise ModelTooLargeError(
                f"Das Modell braucht {size} Bytes, der ML-Dienst darf aber höchstens {limit} Bytes dafür nutzen.",
            )
        if scope != GLOBAL_SCOPE:
            self._evict_until(lambda: self._bytes_in(scope) + size <= limit, scope)
        self._evict_until(lambda: self._bytes_in(None) + size <= self._maximum_bytes, None)

    def _evict_until(self, fits, scope):
        while not fits():
            entry = next((entry for entry in self._models if scope is None or entry[0] == scope), None)
            if entry is None:
                return
            del self._models[entry]

    def _limit_for(self, scope):
        if scope == GLOBAL_SCOPE or self._tenant_maximum_bytes is None:
            return self._maximum_bytes
        return min(self._maximum_bytes, self._tenant_maximum_bytes)

    def _bytes_in(self, scope):
        return sum(model.size_bytes for entry, model in self._models.items() if scope is None or entry[0] == scope)

    def _loaded(self, bundle_path, files, size):
        session = self._session_factory(str(bundle_path / MODEL_FILE))
        resources = {
            file.path.split("/", 1)[1]: (bundle_path / file.path).read_bytes()
            for file in files if file.path.startswith(f"{RESOURCE_DIRECTORY}/")
        }
        return LoadedModel(session, resources, size)

    def _recently_used(self, entry):
        model = self._models.pop(entry, None)
        if model is not None:
            self._models[entry] = model
        return model

    def _loading_lock(self, entry):
        with self._lock:
            return self._loading.setdefault(entry, Lock())
