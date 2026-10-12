import hashlib
import secrets
import sqlite3
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from threading import Lock

from novooa_ml.tenants.tenant import Tenant

TOKEN_PREFIX = "nml_"
_SCHEMA = """
CREATE TABLE IF NOT EXISTS tenants (
  id TEXT PRIMARY KEY,
  registration TEXT NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  last_seen_at TEXT
)
"""
_SEEN_INTERVAL_SECONDS = 60


class TenantAlreadyRegistered(Exception):
    pass


class TenantLimitReached(Exception):
    pass


@dataclass(frozen=True)
class TenantRecord:
    tenant: Tenant
    created_at: str
    last_seen_at: str | None


class TenantRegistry:
    """
    Mandantenliste in SQLite. Gespeichert wird nur der SHA-256 des Tokens; das Token selbst gibt es genau einmal,
    bei der Registrierung. Der Verwaltungsbefehl im Container schreibt in dieselbe Datei.
    """

    def __init__(self, path, maximum_tenants=None, clock=None):
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        self._connection = sqlite3.connect(path, timeout=5, check_same_thread=False, isolation_level=None)
        self._connection.execute("PRAGMA journal_mode=WAL")
        self._connection.execute(_SCHEMA)
        self._maximum = maximum_tenants
        self._clock = clock or (lambda: datetime.now(timezone.utc))
        self._lock = Lock()
        self._seen = {}

    def register(self, tenant_id):
        token = TOKEN_PREFIX + secrets.token_urlsafe(32)
        with self._lock:
            if self._maximum is not None and self._count() >= self._maximum:
                raise TenantLimitReached()
            try:
                self._connection.execute(
                    "INSERT INTO tenants (id, registration, token_hash, created_at) VALUES (?, ?, ?, ?)",
                    (tenant_id, uuid.uuid4().hex, token_hash(token), self._now()),
                )
            except sqlite3.IntegrityError as error:
                raise TenantAlreadyRegistered() from error
        return token

    def authenticate(self, token):
        # Gesucht wird über den Hash: Ein Zeitunterschied beim Vergleich verrät nichts über das Token selbst.
        if not isinstance(token, str) or not token.startswith(TOKEN_PREFIX):
            return None
        with self._lock:
            row = self._connection.execute(
                "SELECT id, registration FROM tenants WHERE token_hash = ?", (token_hash(token),),
            ).fetchone()
        if row is None:
            return None
        tenant = Tenant(*row)
        self._mark_seen(tenant)
        return tenant

    def remove(self, tenant_id):
        """Entfernt den Mandanten und liefert seine letzte Registrierung (oder None)."""
        with self._lock:
            row = self._connection.execute("SELECT id, registration FROM tenants WHERE id = ?", (tenant_id,)).fetchone()
            self._connection.execute("DELETE FROM tenants WHERE id = ?", (tenant_id,))
        return None if row is None else Tenant(*row)

    def records(self):
        with self._lock:
            rows = self._connection.execute(
                "SELECT id, registration, created_at, last_seen_at FROM tenants ORDER BY created_at",
            ).fetchall()
        return [TenantRecord(Tenant(row[0], row[1]), row[2], row[3]) for row in rows]

    def _mark_seen(self, tenant):
        now = self._clock()
        last = self._seen.get(tenant.registration)
        if last is not None and (now - last).total_seconds() < _SEEN_INTERVAL_SECONDS:
            return
        self._seen[tenant.registration] = now
        with self._lock:
            self._connection.execute(
                "UPDATE tenants SET last_seen_at = ? WHERE registration = ?", (now.isoformat(), tenant.registration),
            )

    def _count(self):
        return self._connection.execute("SELECT COUNT(*) FROM tenants").fetchone()[0]

    def _now(self):
        return self._clock().isoformat()


def token_hash(token):
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
