import shutil
from pathlib import Path


def evict_least_recently_used(root, maximum_bytes, keep):
    """Entfernt die am längsten ungenutzten Bündel, bis das Budget passt; `keep` bleibt immer."""
    if maximum_bytes is None:
        return
    bundles = _bundles_by_last_use(Path(root))
    total = sum(size for _, size in bundles)
    for path, size in bundles:
        if total <= maximum_bytes:
            return
        if path.name != keep:
            shutil.rmtree(path, ignore_errors=True)
            total -= size


def _bundles_by_last_use(root):
    directories = [path for path in root.iterdir() if path.is_dir() and not path.name.startswith(".")]
    directories.sort(key=lambda path: path.stat().st_mtime)
    return [(path, _size_of(path)) for path in directories]


def _size_of(directory):
    return sum(path.stat().st_size for path in directory.rglob("*") if path.is_file())
