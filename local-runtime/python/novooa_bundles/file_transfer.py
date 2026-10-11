import hashlib
import os
import urllib.request

CHUNK_BYTES = 1024 * 1024
DOWNLOAD_TIMEOUT_SECONDS = 60


def write_verified(stream, destination, file, length=None):
    """Schreibt einen Datenstrom blockweise und prüft Größe und Prüfsumme, ohne ihn im Speicher zu halten."""
    remaining = file.size_bytes if length is None else length
    if remaining != file.size_bytes:
        raise ValueError(f"Die Größe von {file.path} stimmt nicht.")
    temporary = f"{destination}.{os.getpid()}.{id(stream)}.part"
    try:
        digest = _copy(stream, temporary, remaining)
        _verify(file, os.path.getsize(temporary), digest)
        os.replace(temporary, destination)
    finally:
        if os.path.exists(temporary):
            os.remove(temporary)


def download_verified(url, destination, file):
    with urllib.request.urlopen(url, timeout=DOWNLOAD_TIMEOUT_SECONDS) as response:
        write_verified(response, destination, file)


def _copy(stream, path, length):
    digest = hashlib.sha256()
    with open(path, "wb") as target:
        while length > 0:
            chunk = stream.read(min(CHUNK_BYTES, length))
            if not chunk:
                break
            digest.update(chunk)
            target.write(chunk)
            length -= len(chunk)
    return digest.hexdigest()


def _verify(file, size, digest):
    if size != file.size_bytes:
        raise ValueError(f"Die Größe von {file.path} stimmt nicht.")
    if digest != file.sha256:
        raise ValueError(f"Die Prüfsumme von {file.path} stimmt nicht.")
