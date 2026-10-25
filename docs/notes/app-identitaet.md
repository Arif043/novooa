# Identität in der App

> Wer angemeldet ist, weiß die Runtime aus der Sitzung; die App-interne Auth-Schicht ist nur ein fester Platzhalter für den Arbeitsbereich.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Hinter dem `AuthRepository` steht ein fester `AuthUser('local-user')` mit
  `teamId: 'local-team'` (`LocalWorkspaceAuthRepository`). Die echte
  Anmeldung geschieht außerhalb dieses Seams im `RuntimeConnectionGate`
  (Konto → Session-Token); wer angemeldet ist und welche Rolle er hat,
  liefert `GET /v1/auth/me` an den `CurrentRuntimeUserCubit`
  ([Benutzerkonten](./runtime-benutzerkonten.md)).
- Die Runtime ordnet alles der Person aus der Sitzung zu, nicht der
  Platzhalter-ID.
- Im Browser landet der Token im Web-Backend von `FlutterSecureStorage`
  (WebCrypto + localStorage) und ist damit XSS-exponiert — deutlich schwächer
  als Keychain. Das ist bewusst zu entscheiden und zu dokumentieren (offen).

## Siehe auch

- [Sicherer Token-Speicher im Client](./client-token-speicher.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
