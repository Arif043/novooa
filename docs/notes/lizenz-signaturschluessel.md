# Lizenz-Signaturschlüssel

> Der öffentliche Verifikationsschlüssel steht als Konstante im Code und damit verschleiert im Image; der private Ed25519-Schlüssel existiert nur als Firebase-Secret im Lizenz-Gateway.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Öffentlich: `runtimeLicensePublicKeyPem` in
  `features/licensing/infrastructure/local/runtime-license-public-key.ts`, für alle
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
