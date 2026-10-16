# Lizenz-Signaturschlüssel

> Der öffentliche Verifikationsschlüssel liegt im Repository und im Image; der private Ed25519-Schlüssel existiert nur als Firebase-Secret im Lizenz-Gateway.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Öffentlich: `functions/keys/runtime-license-public-key.pem`, für alle
  Runtimes gleich, kein Kundengeheimnis; dient nur der Offline-Prüfung. Ein
  Server braucht keine Schlüsseldatei.
- Privat: `LOCAL_RUNTIME_LICENSE_SIGNING_KEY`, ausschließlich im Gateway.
  Gehört weder in Image noch Compose-Datei noch Desktop-App noch
  Daten-Volume.
- Ein neues Schlüsselpaar würde alle aktivierten Lizenzen ungültig machen und
  ist nicht vorgesehen.

## Siehe auch

- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
- [Lizenz ausstellen](./lizenz-ausstellen.md)
