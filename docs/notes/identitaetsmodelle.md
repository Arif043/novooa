# Zwei Identitätsmodelle

> Cloud nutzt echte Firebase-Auth-Nutzer; Standalone meldet Konten der Runtime mit Anmeldename und Passwort an, die App-interne Auth-Schicht bleibt dort ein Stub.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

- Standalone: ein `AuthUser('local-user')` mit `teamId: 'local-team'` hinter
  einem Stub-`AuthRepository`. Die echte Anmeldung geschieht außerhalb dieses
  Seams im `RuntimeConnectionGate` (Konto → Session-Token); wer angemeldet ist
  und welche Rolle er hat, liefert `GET /v1/auth/me` an den
  `CurrentRuntimeUserCubit` ([Benutzerkonten](./runtime-benutzerkonten.md)).
  Die Runtime ordnet alles der Person aus der Sitzung zu, nicht der
  Stub-ID.
- Im Browser landet der Token im Web-Backend von `FlutterSecureStorage`
  (WebCrypto + localStorage) und ist damit XSS-exponiert — deutlich schwächer
  als Keychain. Das ist bewusst zu entscheiden und zu dokumentieren (offen).

## Siehe auch

- [Sicherer Token-Speicher im Client](./client-token-speicher.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
