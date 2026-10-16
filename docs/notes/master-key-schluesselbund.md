# Master-Key-Schlüsselbund

> Der Master-Key liegt in einem versionierten JSON-Schlüsselbund im eigenen Volume `novooa-keys`, nie im Image, im Daten-Volume oder auf dem Host.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Beim ersten Start erzeugt der netzwerklose Init-Dienst `key-init` einen
  zufälligen 32-Byte-Master-Key; spätere Starts lassen ihn unberührt.
- Pfad `/var/lib/novooa-keys/runtime-master-key`; Datei `0600`, Verzeichnis
  `0700`, Eigentümer `node` (UID/GID 1000).
- Warum ein Verzeichnis statt einer Datei eingehängt wird: Atomar ersetzte
  Schlüsseldateien bleiben so im Container sichtbar.
- Jede Runtime braucht ihren eigenen Schlüsselbund; nicht zwischen
  Datenverzeichnissen teilen.
- Verlust des Master-Keys: Provider-Keys müssen neu hinterlegt werden.
  Backups umfassen deshalb Daten- **und** Schlüssel-Volume.

Ohne Docker (Desktop-App, `local-runtime:serve`):

```bash
npm --prefix functions run local-runtime:prepare -- --secret-file <pfad>
```

legt den Schlüsselbund als Datei an; die Runtime nutzt und rotiert ihn dort
(`LOCAL_RUNTIME_MASTER_KEY_FILE`).

## Siehe auch

- [Feldverschlüsselung mit Envelopes](./feldverschluesselung-envelope.md)
- [Automatische Master-Key-Rotation](./master-key-automatische-rotation.md)
- [Volumes und Datenablage der Runtime](./runtime-volumes-und-datenablage.md)
