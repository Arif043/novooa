import hashlib
import re
from dataclasses import dataclass

MODEL_FILE = "model.onnx"
RESOURCE_DIRECTORY = "resources"
_SEGMENT = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$")
_SHA256 = re.compile(r"^[a-f0-9]{64}$")


@dataclass(frozen=True)
class BundleFile:
    """Eine Datei eines Bündels; `store_path` ist nur bei Dateien aus dem globalen Speicher gesetzt."""

    path: str
    sha256: str
    size_bytes: int
    store_path: str | None = None


class BundleFilesMissing(Exception):
    def __init__(self, missing):
        super().__init__("Dem Modellbündel fehlen Dateien.")
        self.missing = missing


def bundle_files_from(value):
    if not isinstance(value, list) or not value:
        raise ValueError("Die Dateien des Modellbündels fehlen.")
    files = [bundle_file_from(item) for item in value]
    paths = [file.path for file in files]
    if len(set(paths)) != len(paths):
        raise ValueError("Die Dateien des Modellbündels müssen eindeutig sein.")
    if MODEL_FILE not in paths:
        raise ValueError("Dem Modellbündel fehlt model.onnx.")
    return files


def bundle_key(files):
    lines = "".join(f"{file.path}:{file.sha256}\n" for file in sorted(files, key=lambda item: item.path))
    return hashlib.sha256(lines.encode("utf-8")).hexdigest()


def validated_key(key, files):
    if key != bundle_key(files):
        raise ValueError("Der Schlüssel des Modellbündels passt nicht zu seinen Dateien.")
    return key


def validate_bundle_path(path):
    segments = path.split("/") if isinstance(path, str) else []
    valid = (len(segments) == 1 and _SEGMENT.match(segments[0])) or (
        len(segments) == 2 and segments[0] == RESOURCE_DIRECTORY and _SEGMENT.match(segments[1])
    )
    if not valid or segments[0] == RESOURCE_DIRECTORY and len(segments) == 1:
        raise ValueError("Ein Dateipfad des Modellbündels ist ungültig.")
    return path


def validate_store_path(path):
    if not isinstance(path, str) or not all(_SEGMENT.match(segment) for segment in path.split("/")):
        raise ValueError("Ein Speicherpfad des Modellbündels ist ungültig.")
    return path


def bundle_file_from(value):
    if not isinstance(value, dict):
        raise ValueError("Eine Datei des Modellbündels ist ungültig.")
    store_path = value.get("storePath")
    return BundleFile(
        path=validate_bundle_path(value.get("path")),
        sha256=_sha256_from(value.get("sha256")),
        size_bytes=_size_from(value.get("sizeBytes")),
        store_path=None if store_path is None else validate_store_path(store_path),
    )


def _sha256_from(value):
    if not isinstance(value, str) or not _SHA256.match(value):
        raise ValueError("Die Prüfsumme einer Datei des Modellbündels ist ungültig.")
    return value


def _size_from(value):
    if not isinstance(value, int) or isinstance(value, bool) or value <= 0:
        raise ValueError("Die Größe einer Datei des Modellbündels ist ungültig.")
    return value
