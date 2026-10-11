from pathlib import Path

GLOBAL_SOURCE = "global"
TEAM_SOURCE = "team"


class BundleResolver:
    """
    Findet ein Bündel für den ML-Dienst: zuerst im eigenen Speicher, dann im gemeinsamen Cache des Servers.
    Globale Bündel holt der Cache-Dienst (falls vorhanden) oder der Dienst selbst; Teambündel lädt die Runtime hoch.
    """

    def __init__(self, own_store, global_store, shared_cache_directory=None, shared_cache=None):
        self._own_store = own_store
        self._global_store = global_store
        self._shared_directory = None if shared_cache_directory is None else Path(shared_cache_directory)
        self._shared_cache = shared_cache

    def resolve(self, key, source, files):
        if source == TEAM_SOURCE:
            return self._own_store.path_for(key) or self._own_store.complete_upload(key, files)
        if source != GLOBAL_SOURCE:
            raise ValueError("Die Quelle des Modellbündels ist unbekannt.")
        return self._resolve_global(key, files)

    def _resolve_global(self, key, files):
        if self._shared_cache is not None:
            self._shared_cache.ensure(key, files)
            return self._shared_path(key)
        return self._own_store.install(key, files, self._global_store.fetch)

    def _shared_path(self, key):
        path = self._shared_directory / key if self._shared_directory is not None else None
        if path is None or not path.is_dir():
            raise ValueError("Der gemeinsame Modell-Cache meldet das Bündel, es ist aber nicht eingebunden.")
        return path
