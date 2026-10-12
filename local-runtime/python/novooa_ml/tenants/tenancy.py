from novooa_ml.tenants.tenant import LOCAL_TENANT, validated_tenant_id


class Unauthorized(Exception):
    pass


class RegisteredTenants:
    """Mehrere Runtimes teilen sich den Dienst; jede weist sich mit dem Token aus ihrer Registrierung aus."""

    def __init__(self, registry):
        self._registry = registry

    def tenant_for(self, authorization):
        tenant = self._registry.authenticate(_bearer_token(authorization))
        if tenant is None:
            raise Unauthorized()
        return tenant

    def register(self, payload):
        return {"token": self._registry.register(validated_tenant_id(payload.get("tenantId")))}

    def unregister(self, tenant):
        self._registry.remove(tenant.id)


class SingleTenant:
    """Ein Dienst für genau einen Nutzer (Cloud-Run-Pod, eigener Dienst im Stack): kein Token nötig."""

    def tenant_for(self, authorization):
        return LOCAL_TENANT

    def register(self, payload):
        validated_tenant_id(payload.get("tenantId"))
        return {"token": "local"}

    def unregister(self, tenant):
        return None


def _bearer_token(authorization):
    if not isinstance(authorization, str) or not authorization.startswith("Bearer "):
        return None
    return authorization[len("Bearer "):].strip()
