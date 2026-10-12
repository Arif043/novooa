import shutil
from pathlib import Path
from threading import Lock

from novooa_bundles.bundle_store import BundleStore


class TeamStores:
    """Ein Bündelspeicher je Registrierung eines Mandanten; Teammodelle anderer Mandanten sind darin nie sichtbar."""

    def __init__(self, root, maximum_bytes_per_tenant=None):
        self._root = Path(root)
        self._maximum_bytes = maximum_bytes_per_tenant
        self._stores = {}
        self._lock = Lock()

    def store_for(self, tenant):
        with self._lock:
            store = self._stores.get(tenant.registration)
            if store is None:
                store = BundleStore(self._directory(tenant), self._maximum_bytes)
                self._stores[tenant.registration] = store
            return store

    def remove(self, tenant):
        with self._lock:
            self._stores.pop(tenant.registration, None)
        shutil.rmtree(self._directory(tenant), ignore_errors=True)

    def _directory(self, tenant):
        return self._root / tenant.registration
