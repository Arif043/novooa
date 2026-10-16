# Feldverschlüsselung mit Envelopes

> Standalone verschlüsselt nur sensible Feldwerte (Provider-API-Keys, Verbindungsgeheimnisse, Lizenz-Aktivierungsgeheimnis), jeden mit eigenem Datenschlüssel; der Master-Key verschlüsselt nie direkt.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

SQLite, Dokumente und Dateien sind nicht vollständig verschlüsselt. Eine
Enterprise-Vollverschlüsselung wäre eine zusätzliche Speicherebene mit eigenem
Schlüssel und ist nicht umgesetzt.

Aufbau je Wert (`node:crypto`):

1. Zufälliger 256-Bit-Datenschlüssel; AES-256-GCM verschlüsselt den Wert.
2. HKDF-SHA-256 leitet aus aktivem Master-Key, zufälligem 32-Byte-Salt und
   eindeutig JSON-kodiertem Feldkontext einen Schlüssel ab, der den
   Datenschlüssel mit AES-256-GCM schützt.
3. Beide Verschlüsselungen: eigene 12-Byte-IVs, 16-Byte-Tags. AAD bindet an
   Formatversion, Zweck und Feldkontext.

Feldkontext: bei Provider-Keys die Secret-Referenz (Workspace,
Verbindungs-ID); bei der Lizenz Workspace-, Lizenz- und Aktivierungs-ID.

Die Envelope enthält Version, Master-Key-ID, Salt, verschlüsselten
Datenschlüssel und verschlüsselten Wert samt IVs und Tags. Datenschlüssel
werden nie im Klartext gespeichert; `secret_ref` verweist auf den Eintrag.

Migration: Beim Start übernimmt die Runtime Werte im alten AES-GCM-Format
einmalig in Envelopes, nur nach erfolgreicher Authentifizierung. Fehlender
oder falscher Schlüssel führt zu einem Startfehler, nie zu einer Löschung.
Cloud-Credentials haben eine eigene Verschlüsselung.

## Siehe auch

- [Master-Key-Schlüsselbund](./master-key-schluesselbund.md)
- [Automatische Master-Key-Rotation](./master-key-automatische-rotation.md)
