# Ersteinrichtung der Runtime

> Erst Lizenz-Token einlösen, dann mit demselben Token das erste Admin-Konto anlegen; Besitz des Tokens ist der Vertrauensanker.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Funktioniert von **jedem** Client über Port `8090`, auch für headless
Runtimes, aus dem LAN oder dem Browser.

1. **Lizenz:** `POST /v1/license/activate {activationToken}` löst den Token
   beim Lizenz-Gateway ein; die Runtime speichert dessen SHA-256-Hash in
   `credentials/license-state.json`.
2. **Admin-Konto:** `POST /v1/setup {activationToken, displayName, loginName, password}`
   legt das erste Konto als Admin an, nur wenn der Token zum Hash passt (sonst
   `403`); danach meldet die App es gleich an. Kennt die App den Token nicht
   mehr (Neustart dazwischen), fragt das Formular ihn erneut ab. Weitere
   Konten legen Admins an ([Benutzerkonten](./runtime-benutzerkonten.md)).

Warum diese Reihenfolge: Vor der Aktivierung gibt es den Setup-Handler noch
nicht, er hängt an der erst dann erzeugten Datenbank. Der Client fragt daher:
Adresse → Lizenz → Admin-Konto.

Warum Token statt Netzwerkposition: Wer die Runtime zufällig zuerst erreicht,
kann ohne Token kein Konto anlegen; ein Code aus dem Start-Log ist unnötig.

- `GET /v1/setup` meldet nur `needsSetup` (noch kein Konto mit Passwort) und
  `requiresLicenseToken`, bewusst keine Netzwerkadressen (ohne Anmeldung
  erreichbar).
- `POST /v1/setup` funktioniert genau einmal, danach `409`. Mit dem
  Lizenz-Token gibt es außerdem einen [Notzugang](./runtime-einladungscodes.md)
  für Admins.
- Ein bereits eingelöster Token auf derselben Runtime bestätigt die Lizenz
  ohne Gateway-Anfrage; ein fremder Token ergibt `409 already_activated`.
- Lizenzen von vor dem Token-Nachweis haben keinen Hash: freigeben
  (`POST /v1/license/release`) und mit demselben Token neu aktivieren.
- Fehler: `400 invalid_token`, `401 license_rejected`,
  `409 already_activated`, `502 gateway_unavailable`, `500 activation_failed`;
  Log-Ereignis `local_runtime.license_activation_failed`.

## Siehe auch

- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
