import os

from novooa_bundles.bundle_store import BundleStore
from novooa_bundles.environment import global_store_from_environment, optional_bytes
from novooa_ml.bundles.bundle_resolver import BundleResolver
from novooa_ml.bundles.cache_client import SharedCacheClient

DEFAULT_SESSION_CACHE_BYTES = 4 * 1024 * 1024 * 1024


def resolver_from_environment():
    """Eigener Speicher (beschreibbar, auch Ziel der Uploads), optional der gemeinsame Cache des Servers (nur lesend)."""
    own_store = BundleStore(
        os.environ.get("MODEL_BUNDLE_DIR", "/var/lib/novooa-ml/bundles"),
        optional_bytes("MODEL_BUNDLE_MAX_BYTES"),
    )
    cache_url = os.environ.get("MODEL_CACHE_URL", "").strip()
    resolver = BundleResolver(
        own_store,
        global_store_from_environment(),
        shared_cache_directory=os.environ.get("MODEL_SHARED_CACHE_DIR", "").strip() or None,
        shared_cache=SharedCacheClient(cache_url) if cache_url else None,
    )
    return resolver, own_store


def session_cache_bytes():
    return optional_bytes("MODEL_SESSION_CACHE_BYTES", DEFAULT_SESSION_CACHE_BYTES)
