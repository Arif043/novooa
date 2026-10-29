# Lokaler Start der Runtime

> Der Docker-Build erzeugt Web-App und Runtime gemeinsam; danach Health prüfen und Client starten.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

```bash
docker compose -f docker-compose.server.yaml up --build --detach
docker compose -f docker-compose.local.yaml up --build --detach
curl http://127.0.0.1:8090/healthz
docker compose -f docker-compose.local.yaml ps
flutter run -d macos
```

Der ML-Server wird einmal je Rechner gestartet. Die Runtime-Compose baut die
Web-App direkt ins Image; ein separater Flutter-Build und ein lokales
`build/web`-Verzeichnis sind nicht nötig. Im Browser genügt
`http://<adresse>:8090`, ohne installierten Client. Änderungen an der Web-App
erfordern einen neuen Image-Build.

Vor dem ersten fachlichen Zugriff folgt die
[Ersteinrichtung](./runtime-ersteinrichtung.md).

Ohne Docker (Desktop-App, `local-runtime:serve`) gibt es kein
Schlüssel-Volume; siehe [Master-Key-Schlüsselbund](./master-key-schluesselbund.md).

Nur für die UI ohne Runtime: [UI-Vorschau](./ui-vorschau.md).

## Siehe auch

- [Docker-Stack der Runtime](./runtime-docker-stack.md)
- [Quellcode-Schutz der Images](./runtime-quellcode-schutz.md)
