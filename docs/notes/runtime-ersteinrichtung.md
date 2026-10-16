# Ersteinrichtung der Runtime

> Erst Lizenz-Token einlösen, dann mit demselben Token das Betreiber-Passwort setzen; Besitz des Tokens ist der Vertrauensanker.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Funktioniert von **jedem** Client über Port `8090`, auch für headless
Runtimes, aus dem LAN oder dem Browser.

1. **Lizenz:** `POST /v1/license/activate {activationToken}` löst den Token
   beim Lizenz-Gateway ein; die Runtime speichert dessen SHA-256-Hash in
   `credentials/license-state.json`.
2. **Passwort:** `POST /v1/setup {activationToken, password}` setzt das
   Passwort, nur wenn der Token zum Hash passt (sonst `403`). Kennt die App den
   Token nicht mehr (Neustart dazwischen), fragt das Formular ihn erneut ab.

Warum diese Reihenfolge: Vor der Aktivierung gibt es den Setup-Handler noch
nicht, er hängt an der erst dann erzeugten Datenbank. Der Client fragt daher:
Adresse → Lizenz → Passwort.

Warum Token statt Netzwerkposition: Wer die Runtime zufällig zuerst erreicht,
kann ohne Token kein Passwort setzen; ein Code aus dem Start-Log ist unnötig.

- `GET /v1/setup` meldet nur `needsSetup` und `requiresLicenseToken`, bewusst
  keine Netzwerkadressen (ohne Anmeldung erreichbar).
- `POST /v1/setup` funktioniert genau einmal, danach `409`.
- Ein bereits eingelöster Token auf derselben Runtime bestätigt die Lizenz
  ohne Gateway-Anfrage; ein fremder Token ergibt `409 already_activated`.
- Lizenzen von vor dem Token-Nachweis haben keinen Hash: freigeben
  (`POST /v1/license/release`) und mit demselben Token neu aktivieren.
- Fehler: `400 invalid_token`, `401 license_rejected`,
  `409 already_activated`, `502 gateway_unavailable`, `500 activation_failed`;
  Log-Ereignis `local_runtime.license_activation_failed`.

## Siehe auch

- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Betreiber-Passwort-Pflicht](./betreiber-passwort-pflicht.md)
- [Entwicklungsmodus ohne Lizenz](./runtime-entwicklungsmodus.md)
