import io
import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import patch

import ml_test_support  # noqa: F401  (setzt den Paketpfad)
from novooa_ml.tenants.__main__ import main as tenants_command
from novooa_ml.tenants.tenancy import RegisteredTenants, SingleTenant, Unauthorized
from novooa_ml.tenants.tenant import LOCAL_TENANT
from novooa_ml.tenants.tenant_registry import TenantAlreadyRegistered, TenantLimitReached, TenantRegistry


class TenantRegistryTest(unittest.TestCase):
    def setUp(self):
        self.path = Path(tempfile.mkdtemp()) / "tenants.sqlite3"

    def test_authenticates_with_the_token_but_stores_only_its_hash(self):
        registry = TenantRegistry(self.path)

        token = registry.register("workspace-a")

        self.assertEqual(registry.authenticate(token).id, "workspace-a")
        self.assertIsNone(registry.authenticate("nml_other"))
        self.assertNotIn(token.encode(), self.path.read_bytes())

    def test_a_tenant_id_can_only_be_registered_once(self):
        registry = TenantRegistry(self.path)
        registry.register("workspace-a")

        with self.assertRaises(TenantAlreadyRegistered):
            registry.register("workspace-a")

    def test_limits_the_number_of_tenants(self):
        registry = TenantRegistry(self.path, maximum_tenants=1)
        registry.register("workspace-a")

        with self.assertRaises(TenantLimitReached):
            registry.register("workspace-b")

    def test_a_new_registration_gets_a_new_identity(self):
        registry = TenantRegistry(self.path)
        first = registry.authenticate(registry.register("workspace-a"))
        registry.remove("workspace-a")

        second = registry.authenticate(registry.register("workspace-a"))

        self.assertNotEqual(first.registration, second.registration)

    def test_records_when_a_tenant_was_last_seen(self):
        now = datetime(2026, 1, 1, tzinfo=timezone.utc)
        registry = TenantRegistry(self.path, clock=lambda: now)
        token = registry.register("workspace-a")

        registry.authenticate(token)
        now += timedelta(seconds=10)
        registry.authenticate(token)

        self.assertEqual(registry.records()[0].last_seen_at, "2026-01-01T00:00:00+00:00")


class TenancyTest(unittest.TestCase):
    def test_requires_a_bearer_token(self):
        tenants = RegisteredTenants(TenantRegistry(Path(tempfile.mkdtemp()) / "t.sqlite3"))
        token = tenants.register({"tenantId": "workspace-a"})["token"]

        self.assertEqual(tenants.tenant_for(f"Bearer {token}").id, "workspace-a")
        for header in [None, token, "Bearer nml_wrong"]:
            with self.assertRaises(Unauthorized):
                tenants.tenant_for(header)

    def test_rejects_invalid_tenant_ids(self):
        tenants = RegisteredTenants(TenantRegistry(Path(tempfile.mkdtemp()) / "t.sqlite3"))
        for tenant_id in [None, "", " a", "x" * 201, "a\nb"]:
            with self.assertRaises(ValueError):
                tenants.register({"tenantId": tenant_id})

    def test_a_single_tenant_service_needs_no_token(self):
        self.assertEqual(SingleTenant().tenant_for(None), LOCAL_TENANT)


class TenantCommandTest(unittest.TestCase):
    def test_deletes_a_tenant_with_its_team_bundles(self):
        data = Path(tempfile.mkdtemp())
        with patch.dict("os.environ", {"ML_DATA_DIR": str(data)}):
            registry = TenantRegistry(data / "tenants.sqlite3")
            tenant = registry.authenticate(registry.register("workspace-a"))
            (data / "bundles" / "teams" / tenant.registration).mkdir(parents=True)
            with redirect_stdout(io.StringIO()):
                self.assertEqual(tenants_command(["delete", "workspace-a"]), 0)

        self.assertEqual(registry.records(), [])
        self.assertFalse((data / "bundles" / "teams" / tenant.registration).exists())


if __name__ == "__main__":
    unittest.main()
