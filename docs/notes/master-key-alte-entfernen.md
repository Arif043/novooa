# Alte Master-Keys entfernen

> `--retire-old-keys` entfernt inaktive Keys nach einer erfolgreichen Rotation; ältere Backups brauchen danach einen archivierten Schlüsselbund.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Nur sinnvoll, wenn betroffene Backups abgelaufen sind oder ihr Schlüsselbund
separat archiviert ist.

```bash
docker compose -f docker-compose.local.yaml stop runtime
docker compose -f docker-compose.local.yaml --profile maintenance run --rm key-rotation \
  node lib/shared/local/local-runtime-key-rotation-cli.js --retire-old-keys
docker compose -f docker-compose.local.yaml up --detach runtime
```

Das ist eine reguläre Rotation, **keine** Sanierung nach einem
kompromittierten Master-Key. Dafür müssten zusätzlich neue Datenschlüssel
erzeugt und alle Feldwerte neu verschlüsselt werden.

## Siehe auch

- [Manuelle Master-Key-Rotation](./master-key-manuelle-rotation.md)
- [Master-Key-Schlüsselbund](./master-key-schluesselbund.md)
