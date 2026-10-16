# Lokaler Start der Runtime

> Web-Build erzeugen, Stack starten, Health prüfen, Client mit `NOVOOA_RUNTIME=standalone` starten.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

```bash
flutter build web            # die Runtime liefert dieses Build selbst aus
docker compose -f docker-compose.local.yaml up --build --detach
curl http://127.0.0.1:8090/healthz
docker compose -f docker-compose.local.yaml ps
flutter run -d macos --dart-define=NOVOOA_RUNTIME=standalone
```

`flutter build web` ist optional. Ohne Build ist die Runtime reine API und
antwortet auf App-Pfade mit 404; mit Build genügt im Browser
`http://<adresse>:8090`, ohne installierten Client.

Vor dem ersten fachlichen Zugriff folgt die
[Ersteinrichtung](./runtime-ersteinrichtung.md).

Ohne Docker (Desktop-App, `local-runtime:serve`) gibt es kein
Schlüssel-Volume; siehe [Master-Key-Schlüsselbund](./master-key-schluesselbund.md).

Nur für die UI ohne Runtime: [UI-Vorschau](./ui-vorschau.md).

## Siehe auch

- [Docker-Stack der Runtime](./runtime-docker-stack.md)
- [Entwicklungsmodus ohne Lizenz](./runtime-entwicklungsmodus.md)
