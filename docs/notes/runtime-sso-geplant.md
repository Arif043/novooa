# SSO für die Runtime (geplant)

> Geplant: Enterprise-Kunden melden sich über ihren Identitätsanbieter per OIDC an (Entra ID, Keycloak, Google Workspace); Konten und Rollen bleiben lokal in der Runtime.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Nicht umgesetzt. Vorbereitet ist nur, dass ein Konto kein Passwort braucht:
Passwörter liegen getrennt vom Konto in `runtime_password_credentials`
([Benutzerkonten](./runtime-benutzerkonten.md)).

Vorgesehen:

- neue Tabelle `runtime_identities(provider, subject, uid)`, die eine
  OIDC-Identität einem Konto zuordnet;
- Zuordnung beim ersten Login über eine Einladung oder die E-Mail-Adresse;
- Rollen, Nutzerlimit und Sitzungen bleiben wie bei Passwort-Konten;
- Teil des Pakets „Local Enterprise“ ([Lizenzmodell](./lokales-lizenzmodell.md)).

## Siehe auch

- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
