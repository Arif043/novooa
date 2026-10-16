# Lizenz-Token und Aktivierung

> Ein 16-stelliger Token wird einmal beim Lizenz-Gateway eingelöst; die Runtime erhält eine Ed25519-signierte Lizenz und ein Aktivierungsgeheimnis, das sie an genau diese Aktivierung bindet.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Token-Alphabet: `A-H`, `J-N`, `P-Z`, `2-9`. Der Client sendet ihn nur an
  `POST /v1/license/activate`; die Runtime löst ihn per HTTPS ein.
- Firestore speichert den SHA-256-Hash des Tokens als Dokument-ID, nie den
  Roh-Token. Felder mindestens `licenseId`, `name`, `workspaceId`,
  `expiresAt`, `inUse`.
- Atomar: Ist `inUse` false und die Lizenz gültig, erzeugt das Gateway eine
  neue `activationId` und ein zufälliges Geheimnis, speichert nur dessen Hash,
  setzt `inUse` auf true und liefert signierte Lizenz plus Geheimnis.
- Die Runtime prüft die Signatur offline und speichert beides unter
  `credentials/license-state.json` (restriktive Rechte). Nur das Geheimnis
  wird per [Envelope](./feldverschluesselung-envelope.md) verschlüsselt. Die
  Datei enthält weder Kunden-Token noch Signaturschlüssel noch
  Firebase-Credentials.
- Warum ein Geheimnis statt Gerätefingerabdruck: Die Lizenz ist so an die
  konkrete Aktivierung gebunden, ohne Hardware auszulesen.
- Ohne gültige Lizenz liefern fachliche Endpunkte `423`; bis zum signierten
  Ablaufdatum ist keine ständige Internetverbindung nötig.
- Der SQLite-Arbeitsbereich entsteht deterministisch aus der signierten
  Arbeitsbereich-ID. Die Desktop-App nutzt für UI-Metadaten einen nicht
  sicherheitsrelevanten lokalen Benutzer; maßgeblich ist die Runtime.

## Siehe auch

- [Lizenz freigeben](./lizenz-freigabe.md)
- [Regelmäßige Lizenzprüfung](./lizenz-regelmaessige-pruefung.md)
- [Lizenz-Signaturschlüssel](./lizenz-signaturschluessel.md)
- [Ersteinrichtung der Runtime](./runtime-ersteinrichtung.md)
