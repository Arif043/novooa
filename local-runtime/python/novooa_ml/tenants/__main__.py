"""
Verwaltung der Mandanten im Container (später über den Agenten des Dashboards):
  python -m novooa_ml.tenants list
  python -m novooa_ml.tenants delete <kennung>
Löschen entwertet das Token und entfernt die Teammodelle; die Runtime meldet sich beim nächsten Zugriff neu an.
"""

import sys

from novooa_ml.ml_service_config import registry_from_environment, team_stores_from_environment


def main(arguments):
    command = arguments[0] if arguments else None
    if command == "list" and len(arguments) == 1:
        for record in registry_from_environment().records():
            print(f"{record.tenant.id}\tangemeldet {record.created_at}\tzuletzt {record.last_seen_at or '-'}")
        return 0
    if command == "delete" and len(arguments) == 2:
        return _delete(arguments[1])
    print(__doc__.strip(), file=sys.stderr)
    return 2


def _delete(tenant_id):
    removed = registry_from_environment().remove(tenant_id)
    if removed is None:
        print(f"Kein Mandant mit der Kennung {tenant_id}.", file=sys.stderr)
        return 1
    team_stores_from_environment().remove(removed)
    print(f"Mandant {tenant_id} gelöscht.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
