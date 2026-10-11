import os
import shutil
import uuid
from pathlib import Path
from threading import Lock

from novooa_ml.bundles.bundle_file import BundleFilesMissing
from novooa_ml.bundles.bundle_eviction import evict_least_recently_used
from novooa_ml.bundles.file_transfer import write_verified

INCOMING = ".incoming"
BUILDING = ".building"


class BundleStore:
    """Verzeichnis fertiger Bündel. Ein Bündel erscheint erst vollständig (atomares Umbenennen)."""

    def __init__(self, root, maximum_bytes=None):
        self._root = Path(root)
        self._maximum_bytes = maximum_bytes
        self._locks = {}
        self._locks_guard = Lock()

    def path_for(self, key):
        path = self._root / key
        if not path.is_dir():
            return None
        _touch(path)
        return path

    def install(self, key, files, fetch):
        """Legt ein Bündel an, indem `fetch(file, ziel)` jede Datei geprüft schreibt."""
        with self._lock_for(key):
            existing = self.path_for(key)
            if existing is not None:
                return existing
            building = self._root / BUILDING / f"{key}-{uuid.uuid4().hex}"
            try:
                for file in files:
                    fetch(file, _prepared(building / file.path))
                return self._publish(key, building)
            finally:
                shutil.rmtree(building, ignore_errors=True)

    def receive(self, key, file, stream, length):
        """Nimmt eine hochgeladene Datei für ein Bündel entgegen, das noch nicht vollständig ist."""
        write_verified(stream, _prepared(self._incoming(key) / file.path), file, length)

    def complete_upload(self, key, files):
        with self._lock_for(key):
            existing = self.path_for(key)
            if existing is not None:
                return existing
            incoming = self._incoming(key)
            missing = [file.path for file in files if not (incoming / file.path).is_file()]
            if missing:
                raise BundleFilesMissing(missing)
            return self._publish(key, incoming)

    def _publish(self, key, directory):
        target = self._root / key
        try:
            os.replace(directory, target)
        except OSError:
            # Ein anderer Prozess war schneller; sein Bündel hat denselben geprüften Inhalt.
            if not target.is_dir():
                raise
            shutil.rmtree(directory, ignore_errors=True)
        evict_least_recently_used(self._root, self._maximum_bytes, keep=key)
        return target

    def _incoming(self, key):
        return self._root / INCOMING / key

    def _lock_for(self, key):
        with self._locks_guard:
            return self._locks.setdefault(key, Lock())


def _prepared(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def _touch(path):
    try:
        os.utime(path)
    except OSError:
        pass  # Nur lesend eingebunden: Die Nutzung meldet der Schreiber des Caches selbst.
