import os
from pathlib import Path

from novooa_bundles.bundle_store import BundleStore
from novooa_bundles.environment import global_store_from_environment, optional_bytes, optional_positive_int
from novooa_ml.bundles.bundle_resolver import BundleResolver
from novooa_ml.bundles.team_stores import TeamStores
from novooa_ml.inference_queue import FairInMemoryQueue
from novooa_ml.model_execution import session_factory
from novooa_ml.model_requests import ModelService
from novooa_ml.resource_limits import resource_limits_from_environment
from novooa_ml.session_cache import SessionCache
from novooa_ml.tenants.tenancy import RegisteredTenants, SingleTenant
from novooa_ml.tenants.tenant_registry import TenantRegistry

DEFAULT_MAXIMUM_TENANTS = 50


def data_directory():
    return Path(os.environ.get("ML_DATA_DIR", "/var/lib/novooa-ml"))


def team_stores_from_environment():
    return TeamStores(data_directory() / "bundles" / "teams", optional_bytes("MODEL_TEAM_MAX_BYTES"))


def registry_from_environment():
    return TenantRegistry(
        data_directory() / "tenants.sqlite3", optional_positive_int("ML_MAX_TENANTS", DEFAULT_MAXIMUM_TENANTS),
    )


def tenancy_from_environment():
    """`ML_TENANCY=off`: ein einziger Nutzer ohne Token (Cloud-Run-Pod oder eigener Dienst im Stack)."""
    if os.environ.get("ML_TENANCY", "on").strip() == "off":
        return SingleTenant()
    return RegisteredTenants(registry_from_environment())


def service_from_environment(numpy, onnxruntime):
    limits = resource_limits_from_environment()
    resolver = BundleResolver(
        BundleStore(data_directory() / "bundles" / "global", optional_bytes("MODEL_BUNDLE_MAX_BYTES")),
        global_store_from_environment(),
        team_stores_from_environment(),
    )
    sessions = SessionCache(
        limits.session_bytes, session_factory(onnxruntime, limits.intra_op_threads),
        optional_bytes("MODEL_TENANT_SESSION_BYTES"),
    )
    queue = FairInMemoryQueue(limits.compute_slots, optional_positive_int("ML_TENANT_CONCURRENCY"))
    return ModelService(resolver, sessions, numpy, queue), tenancy_from_environment()
