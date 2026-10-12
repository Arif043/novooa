from dataclasses import dataclass

MAX_TENANT_ID_LENGTH = 200


@dataclass(frozen=True)
class Tenant:
    """
    Ein registrierter Mandant. `id` ist die Kennung der Runtime (ihre Arbeitsbereichs-ID) und kein Geheimnis.
    `registration` wechselt mit jeder Registrierung; Teammodelle und Sitzungen hängen daran, damit eine neu
    vergebene Kennung nie an Reste ihres Vorgängers kommt.
    """

    id: str
    registration: str


LOCAL_TENANT = Tenant("local", "local")


def validated_tenant_id(value):
    if not isinstance(value, str) or not value or value != value.strip():
        raise ValueError("Die Kennung des Mandanten fehlt.")
    if len(value) > MAX_TENANT_ID_LENGTH or not value.isprintable():
        raise ValueError("Die Kennung des Mandanten ist ungültig.")
    return value
