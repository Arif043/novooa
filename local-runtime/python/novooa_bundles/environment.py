import os

from novooa_bundles.global_store import GlobalModelStore, UnavailableGlobalModelStore


def optional_bytes(name, default=None):
    value = os.environ.get(name, "").strip()
    if not value:
        return default
    number = int(value)
    if number <= 0:
        raise ValueError(f"{name} muss größer als 0 sein.")
    return number


def global_store_from_environment():
    url = os.environ.get("MODEL_STORE_URL", "").strip()
    return GlobalModelStore(url) if url else UnavailableGlobalModelStore()
