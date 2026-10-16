# Zwei Identitätsmodelle

> Cloud nutzt echte Firebase-Auth-Nutzer; Standalone kennt einen fest kodierten lokalen Nutzer und meldet sich über das Betreiber-Passwort an.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

- Standalone: ein `AuthUser('local-user')` mit `teamId: 'local-team'` hinter
  einem Stub-`AuthRepository`. Die echte Anmeldung geschieht außerhalb dieses
  Seams im `RuntimeConnectionGate` (Betreiber-Passwort → Session-Token).
- Im Browser landet der Token im Web-Backend von `FlutterSecureStorage`
  (WebCrypto + localStorage) und ist damit XSS-exponiert — deutlich schwächer
  als Keychain. Das ist bewusst zu entscheiden und zu dokumentieren (offen).
- Offen: ein Betreiber-Konto oder mehrere Nutzer, sobald mehrere
  Browser-Clients zugreifen?

## Siehe auch

- [Sicherer Token-Speicher im Client](./client-token-speicher.md)
- [Betreiber-Passwort-Pflicht](./betreiber-passwort-pflicht.md)
