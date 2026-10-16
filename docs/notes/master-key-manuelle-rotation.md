# Manuelle Master-Key-Rotation

> Eine zusätzliche Wartungsrotation läuft bei gestoppter Runtime im netzwerklosen Container `key-rotation`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Vorher Daten- und Schlüssel-Volume gemeinsam sichern.

```bash
docker compose -f docker-compose.local.yaml stop runtime
docker compose -f docker-compose.local.yaml --profile maintenance run --rm --build key-rotation
docker compose -f docker-compose.local.yaml up --detach runtime
```

Der Wartungscontainer läuft als root, um beide Volumes zu bearbeiten; beim
atomaren Austausch bleibt der Eigentümer erhalten. Die Runtime selbst läuft
als `node`.

Ohne Docker:

```bash
npm --prefix functions run local-runtime:rotate-key -- \
  --secret-file /pfad/secrets/runtime-master-key \
  --runtime-root /pfad/runtime-daten
```

Runtime und Wartungsbefehl teilen einen Prozess-Lock im Datenverzeichnis
(`proper-lockfile`); nach einem harten Abbruch verfällt er nach 30 Sekunden.
Eine unterbrochene Rotation setzt derselbe Befehl fort, ohne neuen Key.

## Siehe auch

- [Automatische Master-Key-Rotation](./master-key-automatische-rotation.md)
- [Alte Master-Keys entfernen](./master-key-alte-entfernen.md)
