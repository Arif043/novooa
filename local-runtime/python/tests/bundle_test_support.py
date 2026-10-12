"""Hilfen für Tests rund um Modellbündel: Dateien mit Prüfsumme und Bündel im Speicher."""

import hashlib
import io
from contextlib import contextmanager

import ml_test_support  # noqa: F401  (setzt den Paketpfad)
from novooa_bundles.bundle_file import BundleFile, bundle_key
from novooa_ml.tenants.tenant import Tenant

TENANT_A = Tenant("workspace-a", "a" * 32)
TENANT_B = Tenant("workspace-b", "b" * 32)


def bundle_file(path, content, store_path=None):
    return BundleFile(path, hashlib.sha256(content).hexdigest(), len(content), store_path)


def file_json(file):
    data = {"path": file.path, "sha256": file.sha256, "sizeBytes": file.size_bytes}
    return data if file.store_path is None else {**data, "storePath": file.store_path}


class UnlimitedQueue:
    """Warteschlange ohne Begrenzung für Tests, die nur die fachlichen Anfragen prüfen."""

    @contextmanager
    def slot(self, tenant):
        yield


class FakeGlobalStore:
    """Liefert Inhalte aus einem Wörterbuch statt per HTTP und zählt die Abrufe."""

    def __init__(self, contents):
        self.contents = contents
        self.fetched = []

    def fetch(self, file, destination):
        from novooa_bundles.file_transfer import write_verified

        self.fetched.append(file.path)
        write_verified(io.BytesIO(self.contents[file.path]), destination, file)


def payload_for(files, source="global"):
    return {"modelKey": bundle_key(files), "source": source, "files": [file_json(file) for file in files]}


class RecordingFactory:
    """Erzeugt Platzhalter statt ONNX-Sitzungen und merkt sich die geladenen Pfade."""

    def __init__(self):
        self.paths = []

    def __call__(self, model_path):
        self.paths.append(model_path)
        return object()
