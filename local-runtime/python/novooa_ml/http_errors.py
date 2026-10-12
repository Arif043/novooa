from novooa_bundles.bundle_file import BundleFilesMissing
from novooa_ml.inference_queue import QueueFull
from novooa_ml.session_cache import ModelNotLoadedError, ModelTooLargeError
from novooa_ml.tenants.tenancy import Unauthorized
from novooa_ml.tenants.tenant_registry import TenantAlreadyRegistered, TenantLimitReached

RETRY_AFTER_SECONDS = "1"


class EndpointNotFound(Exception):
    pass


def error_response(error):
    """Übersetzt einen Fehler in (Status, Inhalt, Kopfzeilen); Codes erlauben der Runtime gezielte Reaktionen."""
    if isinstance(error, Unauthorized):
        return 401, {"code": "unauthorized", "error": "Die Runtime ist beim ML-Dienst nicht angemeldet."}, {}
    if isinstance(error, EndpointNotFound):
        return 404, {"error": "Endpunkt nicht gefunden."}, {}
    if isinstance(error, ModelNotLoadedError):
        return 404, {"code": "model_not_loaded"}, {}
    if isinstance(error, BundleFilesMissing):
        return 409, {"code": "bundle_files_missing", "missing": error.missing}, {}
    if isinstance(error, TenantAlreadyRegistered):
        return 409, {"code": "tenant_exists", "error": "Diese Kennung ist beim ML-Dienst bereits angemeldet."}, {}
    if isinstance(error, TenantLimitReached):
        return 403, {"code": "tenant_limit_reached", "error": "Der ML-Dienst nimmt keine weiteren Runtimes an."}, {}
    if isinstance(error, QueueFull):
        return 429, {"code": "busy", "error": "Der ML-Dienst ist ausgelastet."}, {"retry-after": RETRY_AFTER_SECONDS}
    if isinstance(error, ModelTooLargeError):
        return 507, {"code": "model_too_large", "error": str(error)}, {}
    return 422, {"error": str(error)}, {}
